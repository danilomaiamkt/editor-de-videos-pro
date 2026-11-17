#!/usr/bin/env bash
# Motor comum de gerar_vinheta.sh e gerar_transicao.sh: copia o modelo, aplica textos e marca, renderiza no HyperFrames.
# Uso interno: _render_hf.sh <modelo> <segundo da prova> "<selo>" "<titulo>" "<destaque>" "<subtitulo>" <saida.mov>
set -euo pipefail
. "$(dirname "$0")/_config.sh"
MODELO="$1"; PROVA="$2"; SELO="$3"; TITULO="$4"; DESTAQUE="$5"; SUB="$6"; OUT="$7"
CLI="$(ls -d "$HOME"/.claude/plugins/cache/hyperframes/hyperframes/*/skills/hyperframes/scripts/plugin-cli.mjs 2>/dev/null | sort -V | tail -1)"
[ -n "$CLI" ] || { echo "ERRO: plugin HyperFrames não instalado. Rode o instalador de novo."; exit 1; }
[ -f "$FONTE_ARQUIVO" ] || { echo "ERRO: fonte não encontrada: $FONTE_ARQUIVO"; exit 1; }
WORK="$(mktemp -d "${TMPDIR:-/tmp}/$MODELO-XXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SKILL_DIR/assets/$MODELO-template/." "$WORK/"
mkdir -p "$WORK/assets/fonts"
cp "$FONTE_ARQUIVO" "$WORK/assets/fonts/marca.ttf"
"$PY" - "$WORK/index.html" "$SELO" "$TITULO" "$DESTAQUE" "$SUB" <<'FIM_PY'
import sys, html, os
p, selo, titulo, destaque, sub = sys.argv[1:]
s = open(p, encoding="utf-8").read()
trocas = {"{{SELO}}": selo, "{{TITULO}}": titulo, "{{DESTAQUE}}": destaque, "{{SUB}}": sub,
          "{{ASSINATURA}}": os.environ.get("ASSINATURA", "")}
for k in ("COR_ESCURA", "COR_CLARA", "COR_DESTAQUE"):
    trocas["{{%s}}" % k] = os.environ[k]
for k, v in trocas.items():
    s = s.replace(k, html.escape(v))
open(p, "w", encoding="utf-8").write(s)
FIM_PY
cd "$WORK"
node "$CLI" check . 2>&1 | grep -E "error|Check passed|failed" | tail -3 || true
export PRODUCER_BROWSER_GPU_MODE=hardware
node "$CLI" render . --skill=motion-graphics --format mov --resolution landscape-4k --fps 30 -q high -o ./renders/out.mov 2>&1 | grep -E "Render complete|Error|error" | tail -2 || true
[ -f ./renders/out.mov ] || { echo "ERRO: o render não gerou o arquivo."; exit 1; }
mkdir -p "$(dirname "$OUT")"
mv ./renders/out.mov "$OUT"
ffmpeg -v error -y -ss "$PROVA" -i "$OUT" -frames:v 1 -vf scale=1280:-1 "${OUT%.mov}_prova.png" || true
ffprobe -v error -show_entries stream=codec_name,profile,width,height:format=duration -of compact "$OUT"
echo "PRONTO: $OUT"
