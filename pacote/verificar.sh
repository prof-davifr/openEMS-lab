#!/usr/bin/env bash
source "$(dirname "$(readlink -f "$0")")/scripts/ambiente.sh"
echo "Verificando a instalação do openEMS. Aguarde..."
echo
"$PYTHON" -c "import sys, emslab; sys.exit(0 if emslab.verificar() else 1)"
resultado=$?
echo
[[ -n "${EMSLAB_SEM_PAUSA:-}" ]] || read -r -p "Tecle Enter para fechar." _
exit $resultado
