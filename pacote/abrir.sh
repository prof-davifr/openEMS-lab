#!/usr/bin/env bash
source "$(dirname "$(readlink -f "$0")")/scripts/ambiente.sh"
printf '\033]0;openEMS Lab - NAO FECHE ESTA JANELA enquanto usa o Jupyter\007'
if ! "$PYTHON" "$RAIZ/scripts/abrir.py" "$@"; then
    echo
    echo "Algo deu errado. Mande uma foto desta janela ao orientador."
    read -r -p "Tecle Enter para fechar." _
fi
