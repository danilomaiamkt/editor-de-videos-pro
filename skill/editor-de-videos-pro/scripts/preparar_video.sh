#!/usr/bin/env bash
# Prepara um vídeo bruto para edição no Palmier.
# 1. Garante o arquivo local (baixa do iCloud Drive se for placeholder)
# 2. Trata o áudio: highpass, DeepFilterNet (ruído + eco), EQ, gate, compressor, loudnorm -16 LUFS
# 3. Remonta o vídeo original (sem recodificar, HDR preservado) com o áudio tratado
# 4. Opcional --liberar: tira o bruto do disco local (continua no iCloud)
#
# Uso: preparar_video.sh <arquivo_bruto> <slug-do-video> [--liberar]
# Saída: $PASTA_TRABALHO/<slug>/<nome do bruto>_tratado.mov (um vídeo pode juntar vários brutos)
set -euo pipefail
. "$(dirname "$0")/_config.sh"

IN="${1:?arquivo bruto}"
SLUG="${2:?slug do video, ex: a07-medicao-cozinha}"
LIBERAR="${3:-}"
WORK="$PASTA_TRABALHO/$SLUG"
TMP="$WORK/_tmp"
BASE="$(basename "${IN%.*}")"
OUT="$WORK/${BASE}_tratado.mov"
# nunca sobrescrever um tratado existente (o Palmier referencia o arquivo no lugar)
if [ -e "$OUT" ]; then echo "ERRO: $OUT já existe. Apague ou renomeie antes."; exit 1; fi
mkdir -p "$TMP"

# 1. arquivo local
if [ ! -f "$IN" ]; then
  stub="$(dirname "$IN")/.$(basename "$IN").icloud"
  if [ -f "$stub" ]; then
    echo "Baixando do iCloud: $(basename "$IN")"
    brctl download "$IN" >/dev/null 2>&1 || true
    for _ in $(seq 1 720); do [ -f "$IN" ] && break; sleep 5; done
  fi
fi
[ -f "$IN" ] || { echo "ERRO: arquivo não encontrado: $IN"; exit 1; }
# espera terminar de materializar (tamanho estável)
prev=-1; for _ in $(seq 1 120); do cur=$(stat -f %z "$IN"); [ "$cur" = "$prev" ] && break; prev=$cur; sleep 3; done

LIVRE_GB=$(df -g "$HOME" | awk 'NR==2{print $4}')
TAM_GB=$(( $(stat -f %z "$IN") / 1073741824 + 1 ))
if [ "$LIVRE_GB" -lt $(( TAM_GB * 2 + 3 )) ]; then
  echo "ERRO: pouco espaço ($LIVRE_GB GB livres, precisa de ~$(( TAM_GB * 2 + 3 )) GB). Libere vídeos já entregues antes."; exit 1
fi

echo "== Bruto"
LENTE=$("$HOME/.local/bin/exiftool" -s3 -LensModel "$IN" 2>/dev/null | head -1)
echo "Câmera: ${LENTE:-desconhecida}"
case "$LENTE" in
  *front*) echo "ATENÇÃO: CÂMERA FRONTAL. A imagem está espelhada (texto da prancha ao contrário). Na montagem, aplicar flipHorizontal em todos os clipes deste bruto." ;;
esac
ffprobe -v error -show_entries format=duration:stream=codec_name,width,height,r_frame_rate,color_transfer -of compact "$IN"

# 2. áudio
ffmpeg -v error -y -i "$IN" -vn -ac 1 -ar 48000 -af "highpass=f=80" "$TMP/raw.wav"
deep-filter -D --pf --pf-beta 0.03 -a 40 -o "$TMP/df" "$TMP/raw.wav" >/dev/null 2>&1
ffmpeg -v error -y -i "$TMP/df/raw.wav" -af "equalizer=f=300:t=q:w=1.2:g=-3.5,equalizer=f=160:t=q:w=1:g=-1.5,equalizer=f=3500:t=q:w=1.5:g=2,highshelf=f=9000:g=-1.5,agate=threshold=0.012:ratio=2.5:range=0.25:attack=5:release=180,acompressor=threshold=-20dB:ratio=3:attack=8:release=150:makeup=3,loudnorm=I=-16:TP=-1.5:LRA=9" -ar 48000 "$TMP/tratado.wav"

# 3. remux (vídeo copiado, HDR e fps preservados)
VCODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$IN" | head -1)
TAG=""; [ "$VCODEC" = "hevc" ] && TAG="-tag:v hvc1"; [ "$VCODEC" = "h264" ] && TAG="-tag:v avc1"
# shellcheck disable=SC2086
ffmpeg -v error -y -i "$IN" -i "$TMP/tratado.wav" -map 0:v:0 -map 1:a:0 -c:v copy $TAG -c:a aac -b:a 256k -ac 2 -af apad -shortest "$OUT"

echo "== Loudness antes / depois"
for f in "$TMP/raw.wav" "$TMP/tratado.wav"; do
  ffmpeg -hide_banner -i "$f" -af ebur128 -f null - 2>&1 | grep -E "^\s+I:" | tail -1
done
# sincronia (deve ser 0 ms)
"$PY" - "$TMP/raw.wav" "$TMP/tratado.wav" <<'PY' 2>/dev/null || echo "(checagem de sincronia pulada: sem numpy)"
import sys, subprocess, numpy as np
def load(p):
    b = subprocess.run(["ffmpeg","-v","error","-i",p,"-ac","1","-ar","8000","-f","s16le","-"],capture_output=True).stdout
    return np.frombuffer(b,np.int16).astype(float)
a,b = load(sys.argv[1]), load(sys.argv[2])
t = min(len(a),len(b))//2; x = a[t:t+16000]
best = max(range(-400,401), key=lambda l: float(np.dot(x,b[t+l:t+l+16000])))
print(f"Sincronia: {best/8:.1f} ms")
PY

rm -rf "$TMP"
if [ "$LIBERAR" = "--liberar" ] && [[ "$IN" == *"Mobile Documents"* ]]; then
  brctl evict "$IN" >/dev/null 2>&1 && echo "Bruto liberado do disco (continua no iCloud)."
fi
echo "PRONTO: $OUT"
