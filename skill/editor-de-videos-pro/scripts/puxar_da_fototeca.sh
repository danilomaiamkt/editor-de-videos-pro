#!/usr/bin/env bash
# Exporta o ORIGINAL de um vídeo da fototeca desta máquina (app Fotos, sincronizado com o iCloud).
# O Fotos baixa do iCloud se o Mac estiver com "Otimizar armazenamento".
# Uso: puxar_da_fototeca.sh <nome do arquivo, ex: IMG_1234.MOV> <pasta de destino>
# Listar vídeos: puxar_da_fototeca.sh --listar
set -euo pipefail
. "$(dirname "$0")/_config.sh"
if [ "${1:-}" = "--listar" ]; then
  osascript -e 'with timeout of 600 seconds
tell application "Photos"
set r to ""
repeat with m in media items
set f to filename of m
if f ends with ".MOV" or f ends with ".mov" or f ends with ".MP4" or f ends with ".mp4" then set r to r & f & " | " & ((date of m) as «class isot» as string) & " | " & (width of m) & "x" & (height of m) & linefeed
end repeat
return r
end tell
end timeout'
  exit 0
fi
NOME="${1:?nome do arquivo}"; DEST="${2:?pasta de destino}"
mkdir -p "$DEST"
osascript - "$NOME" "$DEST" <<'AS'
on run argv
  set nome to item 1 of argv
  set destino to POSIX file (item 2 of argv)
  with timeout of 3600 seconds
    tell application "Photos"
      set achados to (every media item whose filename is nome)
      if (count of achados) is 0 then error "Não achei " & nome & " na fototeca"
      export {item 1 of achados} to destino with using originals
    end tell
  end timeout
end run
AS
ls -la "$DEST/$NOME"
ffprobe -v error -show_entries format=duration:stream=codec_name,width,height -of compact "$DEST/$NOME"
