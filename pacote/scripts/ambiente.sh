# Define as variáveis de ambiente do pacote. Lido por abrir.sh e verificar.sh.
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export CSXCAD_INSTALL_PATH="$RAIZ/openEMS"
export OPENEMS_INSTALL_PATH="$RAIZ/openEMS"
export PATH="$RAIZ/venv/bin:$RAIZ/openEMS/bin:$PATH"
export PYTHONNOUSERSITE=1
unset PYTHONPATH PYTHONHOME
PYTHON="$RAIZ/venv/bin/python"
