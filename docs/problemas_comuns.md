# Problemas comuns

## Na instalação (Windows)

**O navegador diz que `INSTALAR.bat` "pode ser perigoso".**
Escolha **Manter** (no Edge: os três pontos ao lado do download, depois **Manter**).
O aviso aparece para qualquer arquivo `.bat` baixado da internet.

**"O Windows protegeu o computador" (SmartScreen).**
Clique em **Mais informações** e depois em **Executar assim mesmo**.

**O antivírus bloqueou ou apagou um arquivo.**
Peça ao suporte de TI para liberar a pasta `%LOCALAPPDATA%\openEMS-lab`. Depois, rode o
instalador de novo.

**"Nao foi possivel baixar o pacote".**
A rede do laboratório pode bloquear downloads fora do navegador.
1. Baixe `openEMS-lab-windows.zip` e `openEMS-lab-windows.zip.sha256` pelo navegador, na página do release.
2. Coloque os dois arquivos na mesma pasta do `INSTALAR.bat`.
3. Rode o `INSTALAR.bat` de novo.

**"Nao foi possivel apagar a versao antiga".**
O Jupyter ou o visualizador 3D ainda está aberto. Feche todas as janelas do openEMS Lab e rode o
instalador de novo.

**Pouco espaço em disco.**
A instalação precisa de cerca de 1,5 GB livres (pacote baixado + pacote extraído).

## Na instalação (Linux)

**"curl: comando não encontrado".**
Rode `sudo apt install curl` no terminal e depois cole o comando de instalação de novo.

**A senha não aparece quando eu digito.**
É normal. Digite a senha e tecle Enter.

**"A sua conta precisa de permissão de administrador (sudo)".**
O computador é de outra pessoa ou do laboratório. Peça ao responsável para rodar uma vez
`sudo ~/.cache/openEMS-lab-instalacao/openEMS-Project/scripts/install_deps.sh --auto --python`
e depois rode o comando de instalação de novo, na sua conta.

**O terminal fica muito tempo em "ainda compilando...".**
É normal: a compilação demora de 10 a 30 minutos, mais num computador antigo. Não feche o terminal.
Se o computador travar, ele tem pouca memória: feche o navegador e os outros programas e rode o
comando de instalação de novo.

**"A compilação do openEMS falhou".**
Mande ao orientador o arquivo `~/.local/share/openEMS-lab-instalacao.log`.

**O atalho da Área de Trabalho não abre.**
Clique com o botão direito no atalho e escolha **Permitir executar** (ou **Confiar e abrir**).
Também é possível abrir o **openEMS Lab** pelo menu de aplicativos.

## No uso

**Fechei a janela preta (a janela do terminal) e o Jupyter parou.**
Essa janela é o servidor do Jupyter. Abra o atalho **openEMS Lab** de novo. Os notebooks
salvos não se perdem.

**O PC do laboratório apaga tudo ao reiniciar.**
Alguns laboratórios usam programas de congelamento (por exemplo, Deep Freeze).
Peça ao suporte uma pasta que não é apagada, ou guarde os notebooks num pendrive ou no
Google Drive ao fim de cada aula. O instalador com o ZIP no pendrive leva poucos minutos.

**A simulação demora muito.**
- Use menos células por comprimento de onda: `emslab.Simulacao(celulas_por_lambda=10)`.
  A ressonância muda pouco (confira com 15 antes de concluir algo).
- Use uma banda de frequência menor, por exemplo `f_min=2.5, f_max=4.5`.
- Feche outros programas: o openEMS usa todos os núcleos do processador.

**O visualizador 3D (AppCSXCAD) não abre ou abre preto.**
Alguns PCs sem placa de vídeo não têm OpenGL suficiente. As simulações funcionam sem o visualizador.

**Os resultados ficaram estranhos depois de mudar várias células.**
Use **Kernel > Restart Kernel and Run All Cells**. O Python começa do zero e roda tudo em ordem.

**Quero recomeçar um notebook do zero.**
Apague (ou renomeie) o notebook em `Documentos/openEMS-notebooks` e abra o atalho de novo.
A cópia original volta.

## Mandar um problema ao orientador

Mande:
1. uma foto ou captura da tela com a mensagem de erro;
2. o registro da instalação:
   - Windows: `%LOCALAPPDATA%\openEMS-lab-instalacao.log` (cole o caminho na barra do Explorador de Arquivos);
   - Linux: `~/.local/share/openEMS-lab-instalacao.log`;
3. a saída da verificação:
   - Windows: `VERIFICAR.bat`, que fica em `%LOCALAPPDATA%\openEMS-lab`;
   - Linux: `~/.local/share/openEMS-lab/verificar.sh`, rodado num terminal.
