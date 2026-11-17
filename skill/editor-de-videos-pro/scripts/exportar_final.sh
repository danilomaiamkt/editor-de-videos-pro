#!/usr/bin/env bash
# Gera a versão final (Hotmart, Kiwify, YouTube, área de membros) a partir do export 1080p do Palmier.
# Boa qualidade sem ser o máximo: 1080p, H.264 High, CRF 20 (teto 8 Mbps), 30fps, AAC 192k 48kHz, faststart.
# Fica em torno de 4 a 6 Mbps (uns 35 a 45 MB por minuto), metade ou menos do export bruto do Palmier.
# Uso: exportar_final.sh <export_1080p_do_palmier.mp4> <saida.mp4>
set -euo pipefail
. "$(dirname "$0")/_config.sh"
IN="$1"; OUT="$2"
ffmpeg -v error -y -i "$IN" \
  -c:v libx264 -preset slow -crf 20 -maxrate 8M -bufsize 16M -profile:v high -level 4.1 -pix_fmt yuv420p -r 30 \
  -color_primaries bt709 -color_trc bt709 -colorspace bt709 \
  -c:a aac -b:a 192k -ar 48000 -movflags +faststart "$OUT"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")
BR=$(ffprobe -v error -show_entries format=bit_rate -of csv=p=0 "$OUT")
echo "Tamanho: $(du -h "$OUT" | cut -f1)  ($("$PY" -c "print(round($BR/1e6,1))") Mbps, $(printf '%.0f' "$DUR")s)"
echo "PRONTO: $OUT"
