#!/usr/bin/env bash
# Instalador do openEMS Lab para Linux (openEMS + Python + Jupyter + notebooks).
#
# Num terminal:
#   curl -fsSL https://github.com/prof-davifr/openEMS-lab/releases/latest/download/instalar.sh | bash
#
# - Pede a senha uma vez, para instalar os pacotes de compilação do sistema.
# - Compila o openEMS a partir do código oficial (de 10 a 30 minutos).
# - Instala tudo em ~/.local/share/openEMS-lab, sem mexer no Python do sistema.
# - Os notebooks do aluno ficam em ~/Documentos/openEMS-notebooks e nunca são
#   apagados por este instalador.
#
# Feito para o Linux Mint e o Ubuntu. Os pacotes do sistema vêm do
# scripts/install_deps.sh do openEMS, que também conhece Debian, Fedora e Arch.
# A variável EMSLAB_TESTE=1 tira as perguntas (teste automático).

set -euo pipefail

OPENEMS_TAG="v0.37.0"
REPO="prof-davifr/openEMS-lab"
LAB_VERSAO="main"   # o fluxo do GitHub troca pela tag do release

DADOS="${XDG_DATA_HOME:-$HOME/.local/share}"
DESTINO="$DADOS/openEMS-lab"
TRABALHO="${XDG_CACHE_HOME:-$HOME/.cache}/openEMS-lab-instalacao"
LOG="$DADOS/openEMS-lab-instalacao.log"

titulo() { printf '\n\033[1m%s\033[0m\n' "$*"; }
erro() {
    printf '\n\033[1;31m[ERRO]\033[0m %s\n' "$1"
    shift
    local linha
    for linha in "$@"; do printf '       %s\n' "$linha"; done
    printf '\nInstalação falhou em %s\n' "$(date)" >> "$LOG"
    printf '\nMande uma foto desta janela e o arquivo abaixo ao orientador:\n  %s\n' "$LOG"
    exit 1
}

# roda como administrador; o aluno digita a senha só na primeira vez
admin() {
    if [[ $(id -u) -eq 0 ]]; then "$@"; else sudo "$@"; fi
}

pedir_senha() {
    [[ $(id -u) -eq 0 ]] && return 0
    command -v sudo > /dev/null || erro "O comando sudo não existe neste computador."
    sudo -n true 2> /dev/null && return 0
    echo "Digite a sua senha do computador (a mesma do login) e tecle Enter."
    echo "A senha não aparece na tela enquanto você digita. Isso é normal."
    sudo -v < /dev/tty || erro "Sem a senha, não é possível instalar os pacotes do sistema." \
        "A sua conta precisa de permissão de administrador (sudo)."
}

instalar_git() {
    command -v git > /dev/null && return 0
    titulo "Instalando o git..."
    pedir_senha
    if command -v apt-get > /dev/null; then
        admin apt-get update -q < /dev/null
        admin env DEBIAN_FRONTEND=noninteractive apt-get install -y git ca-certificates < /dev/null
    elif command -v dnf > /dev/null; then
        admin dnf install -y git < /dev/null
    elif command -v pacman > /dev/null; then
        admin pacman -S --noconfirm --needed git < /dev/null
    else
        erro "Não sei instalar pacotes neste Linux. Instale o git e rode o instalador de novo."
    fi
}

# número de compilações em paralelo: cada uma usa até 1,5 GB de memória
tarefas() {
    local nucleos memoria
    nucleos=$(nproc)
    memoria=$(awk '/MemAvailable/ {print int($2 / 1572864)}' /proc/meminfo)
    (( memoria < 1 )) && memoria=1
    echo $(( nucleos < memoria ? nucleos : memoria ))
}

compilar() {
    local fonte="$1" n
    n=$(tarefas)
    echo "A compilação demora de 10 a 30 minutos ($n em paralelo). Não feche esta janela."
    echo "O registro da compilação fica em $TRABALHO/compilacao.log"
    (
        cd "$fonte"
        # a compilação temporária fica na pasta de trabalho, não no /tmp, que pode estar na memória
        export TMPDIR="$TRABALHO/tmp"
        mkdir -p "$TMPDIR"
        ./update_openEMS.sh "$DESTINO/openEMS" --python --skip-dep-check --njobs "$n" \
            --python-venv-mode venv --python-venv-dir "$DESTINO/venv"
    ) > "$TRABALHO/compilacao.log" 2>&1 < /dev/null &
    local pid=$! inicio=$SECONDS
    local minutos=0
    while kill -0 "$pid" 2> /dev/null; do
        sleep 5
        if (( (SECONDS - inicio) / 60 > minutos )); then
            minutos=$(( (SECONDS - inicio) / 60 ))
            echo "    ainda compilando... $minutos min"
        fi
    done
    if ! wait "$pid"; then
        tail -n 40 "$TRABALHO/compilacao.log"
        cat "$fonte"/build_*.log >> "$LOG" 2> /dev/null || true
        erro "A compilação do openEMS falhou."
    fi
    echo "Compilação terminada em $(( (SECONDS - inicio) / 60 )) min."
}

main() {
    if [[ $(id -u) -eq 0 ]]; then
        echo "Não use sudo para rodar o instalador. Rode como o seu usuário:"
        echo "  curl -fsSL https://github.com/$REPO/releases/latest/download/instalar.sh | bash"
        exit 1
    fi
    [[ $(uname -s) == Linux ]] || { echo "Este instalador é para Linux."; exit 1; }

    # usa o Python e as ferramentas do sistema, mesmo com um Anaconda ou um venv ativo
    export PATH="/usr/sbin:/usr/bin:/sbin:/bin"
    unset VIRTUAL_ENV CONDA_PREFIX PYTHONPATH PYTHONHOME
    export PYTHONNOUSERSITE=1

    mkdir -p "$DADOS" "$TRABALHO"
    echo "Instalação iniciada em $(date)" > "$LOG"
    exec > >(tee -a "$LOG") 2>&1

    echo "============================================================"
    echo "  Instalador do openEMS Lab"
    echo "============================================================"
    echo "O programa vai para: $DESTINO"
    echo "Registro da instalação: $LOG"
    grep -h PRETTY_NAME /etc/os-release 2> /dev/null || true

    local livre
    livre=$(df -Pk "$HOME" | awk 'NR == 2 {print int($4 / 1048576)}')
    (( livre >= 4 )) || erro "Há só $livre GB livres na pasta pessoal. A instalação precisa de 4 GB."

    # ------------------------------------------------------------ 1. código
    titulo "[1/5] Baixando o código do openEMS $OPENEMS_TAG e do openEMS Lab..."
    instalar_git
    local fonte="$TRABALHO/openEMS-Project" lab
    rm -rf "$fonte"
    git -c advice.detachedHead=false clone -q --filter=blob:none --recurse-submodules --branch "$OPENEMS_TAG" \
        https://github.com/thliebig/openEMS-Project.git "$fonte" < /dev/null \
        || erro "Não foi possível baixar o openEMS. Confira a internet e rode o instalador de novo."

    # rodando de dentro do repositório, usa os arquivos dele; senão, baixa a versão do release
    local aqui="${BASH_SOURCE[0]:-}"
    if [[ -n "$aqui" && -f "$(dirname "$aqui")/emslab/pyproject.toml" ]]; then
        lab="$(cd "$(dirname "$aqui")" && pwd)"
    else
        lab="$TRABALHO/openEMS-lab"
        rm -rf "$lab"
        git -c advice.detachedHead=false clone -q --depth 1 --branch "$LAB_VERSAO" "https://github.com/$REPO.git" "$lab" < /dev/null \
            || erro "Não foi possível baixar o openEMS Lab. Confira a internet e rode o instalador de novo."
    fi

    # ------------------------------------------------------------ 2. pacotes
    titulo "[2/5] Conferindo os pacotes de compilação do sistema..."
    if ! "$fonte/scripts/install_deps.sh" --check --python > /dev/null 2>&1; then
        echo "Faltam pacotes do sistema (compilador, bibliotecas, Qt). Vou instalar."
        pedir_senha
        admin "$fonte/scripts/install_deps.sh" --auto --python < /dev/null \
            || erro "Não foi possível instalar os pacotes do sistema."
    fi
    echo "Pacotes do sistema OK."

    # ------------------------------------------------------------ 3. openEMS
    titulo "[3/5] Compilando o openEMS..."
    # o venv e o openEMS guardam o caminho completo: compila direto no destino
    rm -rf "$DESTINO"
    mkdir -p "$DESTINO"
    compilar "$fonte"

    # ------------------------------------------------------------ 4. Python
    titulo "[4/5] Instalando o Jupyter e as bibliotecas Python..."
    local py="$DESTINO/venv/bin/python"
    "$py" -m pip install -q --upgrade pip < /dev/null
    "$py" -m pip install -q numpy scipy matplotlib h5py jupyterlab ipykernel scikit-rf "$lab/emslab" < /dev/null \
        || erro "Não foi possível instalar as bibliotecas Python."
    # avisos e notícias do JupyterLab confundem quem está começando
    mkdir -p "$DESTINO/venv/share/jupyter/lab/settings"
    cp "$lab/pacote/overrides.json" "$DESTINO/venv/share/jupyter/lab/settings/"

    cp "$lab/pacote/abrir.sh" "$lab/pacote/verificar.sh" "$DESTINO/"
    mkdir -p "$DESTINO/scripts"
    cp "$lab/pacote/scripts/abrir.py" "$lab/pacote/scripts/ambiente.sh" "$DESTINO/scripts/"
    chmod +x "$DESTINO/abrir.sh" "$DESTINO/verificar.sh"
    cp -r "$lab/notebooks" "$DESTINO/notebooks"
    cp -r "$lab/emslab/src/emslab" "$DESTINO/codigo-emslab"
    cp "$lab/LICENSE" "$DESTINO/"
    printf 'pacote %s\nopenEMS %s\n%s\n' "$LAB_VERSAO" "$OPENEMS_TAG" "$("$py" --version)" > "$DESTINO/versao.txt"

    # ------------------------------------------------------------ 5. atalho e teste
    titulo "[5/5] Preparando a pasta de notebooks, o atalho e o teste..."
    "$py" "$DESTINO/scripts/abrir.py" --preparar
    echo
    EMSLAB_SEM_PAUSA=1 "$DESTINO/verificar.sh" \
        || erro "A verificação falhou."

    rm -rf "$TRABALHO"
    echo
    echo "============================================================"
    echo "  INSTALACAO OK"
    echo "  Para usar: abra \"openEMS Lab\" no menu de aplicativos"
    echo "  ou dê dois cliques no atalho da Área de Trabalho."
    echo "============================================================"
    echo "Instalação terminada em $(date)" >> "$LOG"

    [[ -n "${EMSLAB_TESTE:-}" ]] && return 0
    local resposta
    read -r -p "Abrir o Jupyter agora? [S/n] " resposta < /dev/tty || return 0
    [[ "$resposta" =~ ^[Nn] ]] && return 0
    exec "$DESTINO/abrir.sh"
}

# tudo dentro de main: com "curl | bash", nada roda antes de o script chegar inteiro
main "$@"
