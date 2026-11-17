#!/usr/bin/env bash
# Gera a transição de bloco (HyperFrames, 2,4s, 4K, ProRes 4444 com alpha) nas cores e fonte do config.env.
# A faixa de destaque puxa o painel escuro, que cobre a tela de 0,44s a 2,0s.
# Uso: gerar_transicao.sh "<selo>" "<titulo>" "<destaque>" "<subtitulo>" <saida.mov>
# Ex.:  gerar_transicao.sh "Na prática" "Hora da" "medição." "Cotas gerais do ambiente" "$PASTA_TRABALHO/a01/transicao-1.mov"
exec "$(dirname "$0")/_render_hf.sh" transicao 1.3 "$@"
