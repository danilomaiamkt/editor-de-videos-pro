#!/usr/bin/env bash
# Mostra a configuração em uso e confere as ferramentas. Rodar no passo 0 da skill.
set -uo pipefail
. "$(dirname "$0")/_config.sh"
if [ -f "$CONFIG" ]; then echo "Config: $CONFIG"
else echo "Config: AINDA NÃO EXISTE ($CONFIG). Fazer a configuração da primeira vez (SKILL.md)."; fi
for v in PASTA_TRABALHO PASTA_CONTROLE PASTA_ENTREGA ORIGEM_BRUTOS PASTA_BRUTOS MARCA_NOME ASSINATURA COR_ESCURA COR_CLARA COR_DESTAQUE FONTE_ARQUIVO FONTE_PALMIER IDIOMA TRILHA_DEMONSTRACAO PY; do
  printf '%s=%s\n' "$v" "${!v}"
done
ok() { printf '  %-14s %s\n' "$1" "$2"; }
for b in ffmpeg ffprobe deep-filter exiftool node npx; do
  if command -v "$b" >/dev/null; then ok "$b" OK; else ok "$b" FALTA; fi
done
if [ -d /Applications/PalmierPro.app ] || [ -d "$HOME/Applications/PalmierPro.app" ]; then ok Palmier OK; else ok Palmier FALTA; fi
if [ -f "$FONTE_ARQUIVO" ]; then ok Fonte OK; else ok Fonte "FALTA ($FONTE_ARQUIVO)"; fi
if ls "$HOME"/.claude/plugins/cache/hyperframes/hyperframes/*/skills/hyperframes/scripts/plugin-cli.mjs >/dev/null 2>&1; then ok HyperFrames OK; else ok HyperFrames FALTA; fi
if "$PY" -c "import numpy" 2>/dev/null; then ok numpy OK; else ok numpy FALTA; fi
if "$PY" -c "import faster_whisper" 2>/dev/null; then ok Whisper OK; else ok Whisper "FALTA (opcional)"; fi
if [ -n "$TRILHA_DEMONSTRACAO" ]; then
  if [ -f "$TRILHA_DEMONSTRACAO" ]; then ok Trilha OK; else ok Trilha "FALTA ($TRILHA_DEMONSTRACAO)"; fi
fi
df -g "$HOME" | awk 'NR==2{print "  Disco livre    " $4 " GB"}'
