#!/usr/bin/env python3
# Rodar com o Python da skill: "$HOME/.local/share/editor-de-videos-pro/venv/bin/python" medir_emendas.py ...
"""Mede onde o som começa e termina em janelas do vídeo, para posicionar as emendas.

A transcrição do Palmier marca as palavras até ~0,25s depois do som real; cortar pelo
horário dela come o começo das palavras. Use o resultado assim:
  começo de trecho = primeiro som - 0,3s
  fim de trecho    = último som + 0,2s

Uso: medir_emendas.py <video> <inicio>:<duracao>:<rotulo> [...]
Ex.:  medir_emendas.py aula_tratado.mov 1.5:2:inicio 64.5:2:fim-novamente
Limiar padrão -38 dB (fala no áudio tratado fica entre -15 e -30 dB; silêncio tratado ~ -100 dB).
"""
import math
import struct
import subprocess
import sys
import wave
import tempfile
import os

os.environ["PATH"] = os.path.expanduser("~/.local/bin") + os.pathsep + os.environ.get("PATH", "")
LIMIAR = float(os.environ.get("LIMIAR_DB", "-38"))


def medir(video, ini, dur):
    with tempfile.NamedTemporaryFile(suffix=".wav") as t:
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", str(ini), "-t", str(dur), "-i", video,
                        "-vn", "-ac", "1", "-ar", "16000", t.name], check=True)
        w = wave.open(t.name)
        n = w.getnframes()
        s = struct.unpack("<%dh" % n, w.readframes(n))
    passo = 800  # 50 ms
    com_som = []
    for i in range(0, n, passo):
        g = s[i:i + passo]
        r = math.sqrt(sum(x * x for x in g) / len(g)) if g else 0
        db = 20 * math.log10(r / 32768) if r else -120
        if db > LIMIAR:
            com_som.append(round(ini + i / 16000, 2))
    return com_som


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    video = sys.argv[1]
    for janela in sys.argv[2:]:
        ini, dur, rotulo = janela.split(":", 2)
        som = medir(video, float(ini), float(dur))
        if som:
            print(f"{rotulo:20s} primeiro som {som[0]:8.2f}s  último som {som[-1]:8.2f}s")
        else:
            print(f"{rotulo:20s} sem som na janela {ini}s + {dur}s")


if __name__ == "__main__":
    main()
