#!/usr/bin/env bash
# Instalador do editor-de-videos-pro (skill do Claude Code que edita vídeos no Palmier Pro).
# https://github.com/danilomaiamkt/editor-de-videos-pro
# Instala do zero, sem Homebrew e sem senha de administrador:
#   Claude Code, Palmier Pro, ffmpeg/ffprobe, DeepFilterNet, ExifTool, Node, uv + Python
#   (numpy, faster-whisper), fonte Bricolage Grotesque, plugin HyperFrames, MCP do Palmier e a skill.
# Pode rodar quantas vezes quiser: o que já estiver instalado é pulado.
# Uso: bash instalar.sh   (ou dois cliques em instalar.command)
#  ou: curl -fsSL https://raw.githubusercontent.com/danilomaiamkt/editor-de-videos-pro/main/instalar.sh | bash
set -uo pipefail

NOME="editor-de-videos-pro"
REPO="danilomaiamkt/editor-de-videos-pro"
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share"
SKILL_DESTINO="$HOME/.claude/skills/$NOME"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/instalar-$NOME-XXXX")"
trap 'rm -rf "$TMP"' EXIT
# rodando de dentro da pasta baixada ou via curl | bash (aí baixa o repositório)
PACOTE=""
case "${BASH_SOURCE[0]:-}" in */*|instalar.sh) PACOTE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";; esac
if [ -z "$PACOTE" ] || [ ! -d "$PACOTE/skill/$NOME" ]; then
  echo "Baixando a skill do GitHub..."
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP" || { echo "ERRO: não consegui baixar $REPO"; exit 1; }
  PACOTE="$TMP/$NOME-main"
fi
SKILL_ORIGEM="$PACOTE/skill/$NOME"
mkdir -p "$BIN" "$SHARE"
export PATH="$BIN:$PATH"

passo() { printf '\n\033[1m== %s\033[0m\n' "$1"; }
ok()    { printf '   OK  %s\n' "$1"; }
aviso() { printf '   ATENÇÃO  %s\n' "$1"; }
erro()  { printf '\n   ERRO  %s\n' "$1"; exit 1; }
baixar() { curl -fL --retry 3 --progress-bar -o "$2" "$1"; }
FALHAS=()

# ---------------------------------------------------------------- 0. máquina
passo "Conferindo a máquina"
[ "$(uname -s)" = "Darwin" ] || erro "Isto só roda em Mac. O Palmier Pro não existe para Windows."
[ "$(uname -m)" = "arm64" ] || erro "O Palmier Pro exige Mac com chip Apple (M1 ou mais novo). Este Mac é Intel."
MACOS_MAIOR="$(sw_vers -productVersion | cut -d. -f1)"
[ "$MACOS_MAIOR" -ge 26 ] || erro "O Palmier Pro exige macOS 26 (Tahoe) ou mais novo. Este Mac está no $(sw_vers -productVersion). Atualize em Ajustes do Sistema > Geral > Atualização de Software."
ok "Mac com chip Apple, macOS $(sw_vers -productVersion)"
LIVRE=$(df -g "$HOME" | awk 'NR==2{print $4}')
[ "$LIVRE" -ge 15 ] && ok "$LIVRE GB livres" || aviso "Só $LIVRE GB livres. A instalação cabe, mas cada vídeo 4K usa de 5 a 10 GB enquanto é editada."

# PATH permanente
for rc in "$HOME/.zshrc" "$HOME/.bash_profile"; do
  [ -f "$rc" ] || touch "$rc"
  grep -q '.local/bin' "$rc" || printf '\n# ferramentas do editor-de-videos-pro\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
done

# ---------------------------------------------------------------- 1. Claude Code
passo "Claude Code"
if command -v claude >/dev/null 2>&1; then ok "já instalado ($(claude --version 2>/dev/null | head -1))"
else
  curl -fsSL https://claude.ai/install.sh | bash || FALHAS+=("Claude Code")
  command -v claude >/dev/null 2>&1 && ok "instalado" || aviso "não consegui instalar o Claude Code"
fi

# ---------------------------------------------------------------- 2. Palmier Pro
passo "Palmier Pro (editor de vídeo)"
APP=""
for d in /Applications "$HOME/Applications"; do [ -d "$d/PalmierPro.app" ] && APP="$d/PalmierPro.app"; done
if [ -n "$APP" ]; then ok "já instalado em $APP (ele se atualiza sozinho)"
else
  echo "   Baixando (cerca de 110 MB)..."
  if baixar "https://github.com/palmier-io/palmier-pro/releases/latest/download/PalmierPro.dmg" "$TMP/PalmierPro.dmg"; then
    mkdir -p "$TMP/mnt"
    hdiutil attach -nobrowse -readonly -mountpoint "$TMP/mnt" "$TMP/PalmierPro.dmg" >/dev/null
    DEST=/Applications; [ -w /Applications ] || { DEST="$HOME/Applications"; mkdir -p "$DEST"; }
    ditto "$TMP/mnt/PalmierPro.app" "$DEST/PalmierPro.app"
    hdiutil detach "$TMP/mnt" -quiet || true
    [ -d "$DEST/PalmierPro.app" ] && ok "instalado em $DEST" || FALHAS+=("Palmier Pro")
  else FALHAS+=("Palmier Pro (download)"); aviso "baixe manualmente em https://github.com/palmier-io/palmier-pro/releases/latest"; fi
fi

# ---------------------------------------------------------------- 3. ffmpeg / ffprobe
passo "ffmpeg e ffprobe"
for f in ffmpeg ffprobe; do
  if [ -x "$BIN/$f" ] || command -v "$f" >/dev/null 2>&1; then ok "$f já instalado"; continue; fi
  URL=$(curl -fsL https://www.osxexperts.net/ | grep -oE "https://www\.osxexperts\.net/${f}[0-9]+arm\.zip" | head -1)
  [ -n "$URL" ] || URL="https://www.osxexperts.net/${f}902arm.zip"
  echo "   Baixando $URL"
  if baixar "$URL" "$TMP/$f.zip" && unzip -oq "$TMP/$f.zip" -d "$TMP/$f"; then
    B=$(find "$TMP/$f" -type f -name "$f" | head -1)
    cp "$B" "$BIN/$f" && chmod +x "$BIN/$f" && xattr -c "$BIN/$f" 2>/dev/null
    "$BIN/$f" -version >/dev/null 2>&1 && ok "$f instalado" || FALHAS+=("$f")
  else FALHAS+=("$f (download)"); fi
done

# ---------------------------------------------------------------- 4. DeepFilterNet
passo "DeepFilterNet (limpeza de ruído e eco)"
if [ -x "$BIN/deep-filter" ]; then ok "já instalado"
else
  if baixar "https://github.com/Rikorose/DeepFilterNet/releases/download/v0.5.6/deep-filter-0.5.6-aarch64-apple-darwin" "$BIN/deep-filter"; then
    chmod +x "$BIN/deep-filter"; xattr -c "$BIN/deep-filter" 2>/dev/null
    "$BIN/deep-filter" --version >/dev/null 2>&1 && ok "instalado" || FALHAS+=("deep-filter")
  else FALHAS+=("deep-filter (download)"); fi
fi

# ---------------------------------------------------------------- 5. ExifTool
passo "ExifTool (detecta câmera frontal, que grava espelhado)"
if [ -x "$BIN/exiftool" ]; then ok "já instalado"
else
  V=$(curl -fsL https://exiftool.org/ver.txt | tr -d '[:space:]')
  if [ -n "$V" ] && { baixar "https://sourceforge.net/projects/exiftool/files/Image-ExifTool-$V.tar.gz/download" "$TMP/exif.tgz" || baixar "https://exiftool.org/Image-ExifTool-$V.tar.gz" "$TMP/exif.tgz"; }; then
    rm -rf "$SHARE/exiftool"; mkdir -p "$SHARE/exiftool"
    tar -xzf "$TMP/exif.tgz" -C "$SHARE/exiftool" --strip-components 1
    ln -sf "$SHARE/exiftool/exiftool" "$BIN/exiftool"
    "$BIN/exiftool" -ver >/dev/null 2>&1 && ok "instalado ($V)" || { FALHAS+=("exiftool"); aviso "precisa do Perl do macOS"; }
  else FALHAS+=("exiftool (download)"); fi
fi

# ---------------------------------------------------------------- 6. Node
passo "Node (usado pelo HyperFrames para gerar vinheta e transição)"
NODE_OK=0
if command -v node >/dev/null 2>&1; then
  NV=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
  [ "$NV" -ge 20 ] && NODE_OK=1
fi
if [ "$NODE_OK" = 1 ]; then ok "já instalado ($(node --version))"
else
  NVER=$(curl -fsL https://nodejs.org/dist/index.json | /usr/bin/python3 -c "import json,sys;print([x['version'] for x in json.load(sys.stdin) if x['lts']][0])" 2>/dev/null || echo v24.11.1)
  if baixar "https://nodejs.org/dist/$NVER/node-$NVER-darwin-arm64.tar.gz" "$TMP/node.tgz"; then
    rm -rf "$SHARE/node"; mkdir -p "$SHARE/node"
    tar -xzf "$TMP/node.tgz" -C "$SHARE/node" --strip-components 1
    for b in node npm npx; do ln -sf "$SHARE/node/bin/$b" "$BIN/$b"; done
    node --version >/dev/null 2>&1 && ok "instalado ($NVER)" || FALHAS+=("node")
  else FALHAS+=("node (download)"); fi
fi

# ---------------------------------------------------------------- 7. uv + Python da skill
passo "Python da skill (numpy e Whisper local)"
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh >/dev/null 2>&1 || FALHAS+=("uv")
fi
VENV="$SHARE/$NOME/venv"
if command -v uv >/dev/null 2>&1; then
  [ -x "$VENV/bin/python" ] || uv venv --quiet --python 3.12 "$VENV"
  uv pip install --quiet --python "$VENV/bin/python" numpy faster-whisper && ok "Python 3.12 com numpy e faster-whisper em $VENV" || FALHAS+=("Python da skill")
fi

# ---------------------------------------------------------------- 8. Fonte
passo "Fonte Bricolage Grotesque (legendas, vinheta e transição)"
FONTE="$HOME/Library/Fonts/BricolageGrotesque-Variable.ttf"
if [ -f "$FONTE" ]; then ok "já instalada"
else
  mkdir -p "$HOME/Library/Fonts"
  baixar "https://github.com/google/fonts/raw/main/ofl/bricolagegrotesque/BricolageGrotesque%5Bopsz,wdth,wght%5D.ttf" "$FONTE" && ok "instalada" || FALHAS+=("fonte Bricolage")
fi

# ---------------------------------------------------------------- 9. Plugin HyperFrames + MCP do Palmier
passo "Plugin HyperFrames e conexão do Claude com o Palmier"
if command -v claude >/dev/null 2>&1; then
  if ls "$HOME"/.claude/plugins/cache/hyperframes/hyperframes/*/skills/hyperframes/scripts/plugin-cli.mjs >/dev/null 2>&1; then ok "HyperFrames já instalado"
  else
    claude plugin marketplace add heygen-com/hyperframes >/dev/null 2>&1
    claude plugin install hyperframes@hyperframes >/dev/null 2>&1
    ls "$HOME"/.claude/plugins/cache/hyperframes/hyperframes/*/skills/hyperframes/scripts/plugin-cli.mjs >/dev/null 2>&1 \
      && ok "HyperFrames instalado" \
      || { FALHAS+=("plugin HyperFrames"); aviso "dentro do Claude Code, rode: /plugin marketplace add heygen-com/hyperframes  e depois  /plugin install hyperframes@hyperframes"; }
  fi
  if claude mcp get palmier-pro >/dev/null 2>&1; then ok "MCP palmier-pro já configurado"
  else
    claude mcp add --scope user --transport http palmier-pro http://127.0.0.1:19789/mcp >/dev/null 2>&1 \
      && ok "MCP palmier-pro configurado" \
      || { FALHAS+=("MCP palmier-pro"); aviso "rode: claude mcp add --scope user --transport http palmier-pro http://127.0.0.1:19789/mcp"; }
  fi
else
  FALHAS+=("HyperFrames e MCP (sem Claude Code)")
fi

# ---------------------------------------------------------------- 10. Skill
passo "Skill $NOME"
mkdir -p "$HOME/.claude/skills"
if [ -d "$SKILL_DESTINO" ]; then
  BK="$HOME/.claude/skills/.backup-$NOME-$(date +%Y%m%d-%H%M%S)"
  mv "$SKILL_DESTINO" "$BK"; ok "versão anterior guardada em $BK"
fi
ditto "$SKILL_ORIGEM" "$SKILL_DESTINO"
xattr -cr "$SKILL_DESTINO" 2>/dev/null
chmod +x "$SKILL_DESTINO"/scripts/*.sh "$SKILL_DESTINO"/scripts/*.py "$SKILL_DESTINO/scripts/icloud_status"
ok "instalada em $SKILL_DESTINO"
if [ -f "$HOME/.config/$NOME/config.env" ]; then ok "configuração mantida (~/.config/$NOME/config.env)"
else ok "configuração (pastas e marca) é feita pelo Claude no primeiro uso"; fi

# ---------------------------------------------------------------- resumo
passo "Resumo"
"$SKILL_DESTINO/scripts/config.sh"
if [ ${#FALHAS[@]} -gt 0 ]; then
  printf '\n   Ficou faltando: %s\n   Rode o instalador de novo (ele pula o que já está pronto). Se continuar falhando, mande este print.\n' "${FALHAS[*]}"
else
  printf '\n   Tudo instalado.\n'
fi
cat <<'FIM'

Próximos passos:
  1. Abra o Palmier Pro (pasta Aplicativos) e entre na conta se ele pedir.
  2. Feche e abra o Terminal, digite  claude  e faça login com a sua conta Claude (Pro ou Max).
  3. Com o Palmier aberto, peça ao Claude:  /editor-de-videos-pro
     Na primeira vez ele pergunta de onde vêm os vídeos, onde entregar e as cores e a fonte da sua marca.
FIM
