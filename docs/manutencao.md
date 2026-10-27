# Manutenção: como o pacote é feito

O fluxo [`.github/workflows/pacote.yml`](../.github/workflows/pacote.yml) tem três jobs.

O job `windows` roda num Windows do GitHub Actions e:

1. baixa o ZIP oficial do openEMS para Windows (versão e SHA256 fixos no início do arquivo);
2. instala um Python 3.13 portátil (python-build-standalone, pelo `uv`) e as bibliotecas;
3. instala as wheels do openEMS que vêm no ZIP oficial e o pacote `emslab`;
4. monta `openEMS-lab-windows.zip`;
5. testa o `INSTALAR.bat` numa conta com espaço e acento no nome e executa os notebooks 00 a 03;
6. guarda o ZIP como artefato do job.

O pacote do Windows é portátil: o Python não tem caminhos absolutos, e os atalhos usam `python -m`.

O job `linux` roda o `instalar.sh` num contêiner do Linux Mint 22.3, como um usuário comum
com sudo, e executa os notebooks 00 a 03.

No Linux não há binário oficial do openEMS, e o pacote do Debian é de 2019. Por isso, o
`instalar.sh` compila o openEMS no computador do aluno com os scripts do próprio openEMS
(`scripts/install_deps.sh` e `update_openEMS.sh`). A compilação vai direto para
`~/.local/share/openEMS-lab`, porque o venv e as bibliotecas guardam o caminho completo.

O job `release`, numa tag `v*`, fixa a tag no `instalar.sh` e publica o release com
`INSTALAR.bat`, o ZIP, o SHA256 e o `instalar.sh`.

## Publicar uma nova versão

```bash
git tag v0.2.0
git push origin v0.2.0
```

## Trocar a versão do openEMS

- Windows: mude `OPENEMS_TAG`, `OPENEMS_ZIP` e `OPENEMS_SHA256` no fluxo. As wheels do ZIP têm de
  existir para a versão do Python em `PYTHON_VERSION` (a v0.37.0-rc3 tem cp313 e cp314).
- Linux: mude `OPENEMS_TAG` no início do `instalar.sh`.

## Testar o instalador do Linux num Linux Mint limpo

```bash
docker run --rm -it -v "$PWD":/repo:ro linuxmintd/mint22.3-amd64 bash -c '
  apt-get update && apt-get install -y sudo
  useradd -m aluno && echo "aluno ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/aluno
  cp -r /repo /home/aluno/lab && chown -R aluno: /home/aluno/lab
  sudo -u aluno -H env EMSLAB_TESTE=1 EMSLAB_SEM_JANELA=1 bash /home/aluno/lab/instalar.sh'
```

## Desenvolver o `emslab` no Linux

```bash
pip install -e emslab
export CSXCAD_INSTALL_PATH=$HOME/opt/openEMS OPENEMS_INSTALL_PATH=$HOME/opt/openEMS
python -c "import emslab; emslab.verificar()"
```

## Estrutura

```
INSTALAR.bat                  instalador do Windows (também vai no release)
instalar.sh                   instalador do Linux (também vai no release)
pacote/                       arquivos que vão para dentro da instalação
  ABRIR.bat, VERIFICAR.bat    Windows
  abrir.sh, verificar.sh      Linux
  scripts/abrir.py            copia os notebooks, cria o atalho e abre o JupyterLab
  scripts/ambiente.bat        variáveis de ambiente do openEMS (Windows)
  scripts/ambiente.sh         variáveis de ambiente do openEMS (Linux)
emslab/                       pacote Python de apoio (geometria, simulação, gráficos)
notebooks/                    notebooks em português
docs/                         documentação
```
