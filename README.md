# openEMS Lab

Instalação pronta para simular antenas e sensores de micro-ondas com o
[openEMS](https://openems.de) no **Windows** e no **Linux** (Mint, Ubuntu).
Tudo roda no navegador, com notebooks Jupyter em português.

O openEMS Lab traz o openEMS, um Python próprio, o JupyterLab, o pacote de apoio `emslab` e
uma sequência de notebooks que vai do básico até um sensor patch sobre um revestimento
de polímero aplicado em metal (ensaio não destrutivo).

## Instalação no Windows (uma vez)

Não precisa de permissão de administrador nem de compilar nada.

1. Abra a página do [último release](https://github.com/prof-davifr/openEMS-win/releases/latest).
2. Em **Assets**, clique em **`INSTALAR.bat`** para baixar o arquivo.
   - Se o navegador avisar que o arquivo "pode ser perigoso", escolha **Manter**.
3. Dê dois cliques em `INSTALAR.bat` na pasta Downloads.
   - Se aparecer **"O Windows protegeu o computador"**, clique em **Mais informações** e depois em
     **Executar assim mesmo**. O aviso aparece porque o arquivo veio da internet.
4. Espere a mensagem **INSTALACAO OK** (de 5 a 15 minutos; o pacote tem cerca de 400 MB).

O instalador cria o atalho **openEMS Lab** na Área de Trabalho.

## Instalação no Linux (uma vez)

1. Abra o **Terminal** (no Linux Mint: menu > Terminal, ou Ctrl + Alt + T).
2. Copie o comando abaixo, cole no terminal (Ctrl + Shift + V) e tecle Enter:

   ```bash
   curl -fsSL https://github.com/prof-davifr/openEMS-lab/releases/latest/download/instalar.sh | bash
   ```

3. Quando o instalador pedir, digite a sua senha do computador e tecle Enter.
   - A senha não aparece enquanto você digita. Isso é normal.
4. Espere a mensagem **INSTALACAO OK** (de 15 a 40 minutos: o instalador compila o openEMS).
   - Não feche o terminal. A cada minuto aparece "ainda compilando...".

O instalador cria o item **openEMS Lab** no menu de aplicativos e na Área de Trabalho.
Se o Mint perguntar se confia no atalho da Área de Trabalho, escolha **Confiar e abrir**.

## Uso diário

1. Abra o **openEMS Lab** pelo atalho na Área de Trabalho (no Linux, também pelo menu).
2. O Jupyter abre no navegador. Os notebooks aparecem no painel da esquerda.
3. **Não feche a janela do terminal** enquanto usa o Jupyter. As mensagens do openEMS aparecem nela.
4. Para encerrar: salve (Ctrl + S), feche o navegador e depois feche a janela do terminal.

## Sequência de notebooks

| Notebook | Conteúdo | Tempo |
|---|---|---|
| `00_verificar_instalacao` | confere a instalação | 1 min |
| `01_jupyter_em_10_minutos` | Jupyter, Python, numpy e gráficos | 10 min |
| `02_patch_no_ar` | primeira simulação com a API do openEMS, passo a passo | 20 min |
| `03_patch_sobre_polimero_e_metal` | o sensor sobre a amostra; comparação com o ar | 15 min |
| `04_varrer_espessura_e_permissividade` | varredura paramétrica e curva de calibração simulada | 20 min |
| `05_defeito_vazio` | vazios no revestimento e uma varredura em linha | 20 min |

Os notebooks ficam na pasta **Documentos/openEMS-notebooks**. Uma reinstalação nunca apaga
estes arquivos: ela só copia os notebooks novos.

## Onde ficam as coisas

| O quê | Windows | Linux |
|---|---|---|
| Programa (openEMS, Python, Jupyter) | `%LOCALAPPDATA%\openEMS-lab` | `~/.local/share/openEMS-lab` |
| Seus notebooks e figuras | `Documentos\openEMS-notebooks` | `~/Documentos/openEMS-notebooks` |
| Dados das simulações (pode apagar) | `openEMS-simulacoes` na pasta de usuário | `~/openEMS-simulacoes` |
| Registro da instalação | `%LOCALAPPDATA%\openEMS-lab-instalacao.log` | `~/.local/share/openEMS-lab-instalacao.log` |

## Problemas

Veja [docs/problemas_comuns.md](docs/problemas_comuns.md). Para conferir a instalação:

- no Windows, dê dois cliques em `VERIFICAR.bat` dentro de `%LOCALAPPDATA%\openEMS-lab`;
- no Linux, rode `~/.local/share/openEMS-lab/verificar.sh` num terminal.

Para entender o que o openEMS calcula, leia [docs/como_funciona.md](docs/como_funciona.md).

## Sem internet no laboratório (Windows)

Copie para um pendrive, na mesma pasta, os três arquivos do release:
`INSTALAR.bat`, `openEMS-lab-windows.zip` e `openEMS-lab-windows.zip.sha256`.
No PC do laboratório, dê dois cliques em `INSTALAR.bat` dentro do pendrive. O instalador usa o
ZIP local e não baixa nada.

---

## Para o orientador: como o pacote é feito

O fluxo [`.github/workflows/pacote.yml`](.github/workflows/pacote.yml) tem três jobs.

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

### Publicar uma nova versão

```bash
git tag v0.2.0
git push origin v0.2.0
```

### Trocar a versão do openEMS

- Windows: mude `OPENEMS_TAG`, `OPENEMS_ZIP` e `OPENEMS_SHA256` no fluxo. As wheels do ZIP têm de
  existir para a versão do Python em `PYTHON_VERSION` (a v0.37.0-rc3 tem cp313 e cp314).
- Linux: mude `OPENEMS_TAG` no início do `instalar.sh`.

### Testar o instalador do Linux num Linux Mint limpo

```bash
docker run --rm -it -v "$PWD":/repo:ro linuxmintd/mint22.3-amd64 bash -c '
  apt-get update && apt-get install -y sudo
  useradd -m aluno && echo "aluno ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/aluno
  cp -r /repo /home/aluno/lab && chown -R aluno: /home/aluno/lab
  sudo -u aluno -H env EMSLAB_TESTE=1 EMSLAB_SEM_JANELA=1 bash /home/aluno/lab/instalar.sh'
```

### Desenvolver o `emslab` no Linux

```bash
pip install -e emslab
export CSXCAD_INSTALL_PATH=$HOME/opt/openEMS OPENEMS_INSTALL_PATH=$HOME/opt/openEMS
python -c "import emslab; emslab.verificar()"
```

### Estrutura

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

## Licença

GPL-3.0-or-later, a mesma do openEMS, que vai dentro da instalação.
O openEMS é de Thorsten Liebig e colaboradores: <https://github.com/thliebig/openEMS-Project>.
