#!/usr/bin/env bash
# Gera a vinheta de abertura (HyperFrames, 3,6s, 4K, ProRes 4444 com alpha) nas cores, fonte e assinatura do config.env.
# O painel cobre a tela desde o primeiro frame; aos 3,1s sai pela direita revelando o vídeo.
# Uso: gerar_vinheta.sh "<selo>" "<titulo>" "<destaque>" "<subtitulo>" <saida.mov>
# Ex.:  gerar_vinheta.sh "Aula prática" "Bancada se mede" "por baixo." "Vão, altura, nível e cuba" "$PASTA_TRABALHO/a02/vinheta.mov"
exec "$(dirname "$0")/_render_hf.sh" vinheta 1.8 "$@"
