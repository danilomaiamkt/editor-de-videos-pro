#!/usr/bin/env bash
# Comprime o export 1080p do Palmier para aprovação no WhatsApp (720p H.264, alvo <= 90 MB, faststart; limite do WhatsApp para vídeo é 100 MB).
# Uso: exportar_whatsapp.sh <entrada_1080p.mp4> [saida.mp4]
set -euo pipefail
. "$(dirname "$0")/_config.sh"
IN="$1"; OUT="${2:-${IN%.*}_WhatsApp.mp4}"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN")
# bitrate de vídeo para caber em ~90 MB, entre 1200k e 3500k
VB=$("$PY" -c "d=$DUR; v=int(90*8*1024/d - 128); print(max(1200, min(3500, v)))")
LOG="$(mktemp -d)/wa"
ffmpeg -v error -y -i "$IN" -vf scale=1280:720:flags=lanczos -c:v libx264 -preset slow -profile:v high -pix_fmt yuv420p -b:v ${VB}k -pass 1 -passlogfile "$LOG" -an -f mp4 /dev/null
ffmpeg -v error -y -i "$IN" -vf scale=1280:720:flags=lanczos -c:v libx264 -preset slow -profile:v high -pix_fmt yuv420p -b:v ${VB}k -pass 2 -passlogfile "$LOG" -c:a aac -b:a 128k -ar 48000 -movflags +faststart "$OUT"
rm -rf "$(dirname "$LOG")"
echo "Tamanho: $(du -h "$OUT" | cut -f1)  (vídeo ${VB}k, $(printf '%.0f' "$DUR")s)"
[ "$(stat -f %z "$OUT")" -lt 100000000 ] || echo "ATENÇÃO: passou de 100 MB, WhatsApp manda como documento."
echo "PRONTO: $OUT"
