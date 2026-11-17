#!/bin/bash
# Dois cliques para instalar. Se o Mac bloquear: botão direito > Abrir > Abrir.
cd "$(dirname "$0")" || exit 1
bash ./instalar.sh
echo
read -r -p "Pressione Enter para fechar."
