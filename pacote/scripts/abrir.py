"""Prepara a pasta de trabalho do aluno e abre o JupyterLab.

Uso:
    python abrir.py               copia os notebooks novos, cria o atalho e abre o Jupyter
    python abrir.py --preparar    só copia os notebooks e cria o atalho
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
NOME_ATALHO = "openEMS Lab.lnk"
ITEM_DE_MENU = """[Desktop Entry]
Type=Application
Name=openEMS Lab
Comment=Abre o Jupyter com o openEMS
Exec="{abrir}"
Terminal=true
Icon=applications-science
Categories=Education;Science;
"""


def pasta_especial(csidl, xdg, padrao):
    """Pasta do usuário (Documentos, Área de Trabalho) no idioma do sistema.

    No Windows, acha a pasta mesmo se ela estiver no OneDrive. No Linux, usa o
    xdg-user-dir, que dá "Documentos" e "Área de Trabalho" num sistema em português.
    """
    if os.name != "nt":
        try:
            saida = subprocess.run(["xdg-user-dir", xdg], capture_output=True, text=True).stdout.strip()
        except OSError:
            return padrao
        # sem configuração, o xdg-user-dir responde com a pasta pessoal
        if saida and Path(saida) != Path.home():
            return Path(saida)
        return padrao
    import ctypes
    from ctypes import wintypes

    buffer = ctypes.create_unicode_buffer(wintypes.MAX_PATH)
    if ctypes.windll.shell32.SHGetFolderPathW(None, csidl, None, 0, buffer) == 0:
        return Path(buffer.value)
    return padrao


def pasta_notebooks():
    return pasta_especial(0x0005, "DOCUMENTS", Path.home() / "Documents") / "openEMS-notebooks"


def copiar_notebooks(destino):
    """Copia só os notebooks que ainda não existem: nunca apaga o trabalho do aluno."""
    destino.mkdir(parents=True, exist_ok=True)
    novos = []
    for origem in sorted((RAIZ / "notebooks").glob("*.ipynb")):
        alvo = destino / origem.name
        if not alvo.exists():
            shutil.copy2(origem, alvo)
            novos.append(origem.name)
    return novos


def criar_atalho():
    """Cria o atalho 'openEMS Lab' na Área de Trabalho (e no menu, no Linux)."""
    if os.name != "nt":
        return criar_atalho_linux()
    area_de_trabalho = pasta_especial(0x0010, "DESKTOP", Path.home() / "Desktop")
    area_de_trabalho.mkdir(parents=True, exist_ok=True)
    atalho = area_de_trabalho / NOME_ATALHO
    # os caminhos vão por variáveis de ambiente, para não ter problema com espaços e acentos
    ambiente = dict(os.environ,
                    ATALHO=str(atalho),
                    ALVO=str(RAIZ / "ABRIR.bat"),
                    PASTA=str(RAIZ),
                    ICONE=str(RAIZ / "openEMS" / "AppCSXCAD.exe") + ",0")
    ambiente.pop("PSModulePath", None)  # o do PowerShell 7 quebra o PowerShell 5.1
    comando = ("$s = (New-Object -ComObject WScript.Shell).CreateShortcut($env:ATALHO); "
               "$s.TargetPath = $env:ALVO; $s.WorkingDirectory = $env:PASTA; "
               "$s.IconLocation = $env:ICONE; $s.Description = 'Abre o Jupyter com o openEMS'; $s.Save()")
    resultado = subprocess.run(["powershell", "-NoProfile", "-NonInteractive", "-Command", comando],
                               env=ambiente, capture_output=True, text=True)
    if resultado.returncode != 0:
        print("Aviso: não foi possível criar o atalho na Área de Trabalho.")
        print(resultado.stderr.strip())
        return None
    return atalho


def criar_atalho_linux():
    texto = ITEM_DE_MENU.format(abrir=RAIZ / "abrir.sh")

    dados = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local" / "share")
    menu = dados / "applications"
    menu.mkdir(parents=True, exist_ok=True)
    (menu / "openems-lab.desktop").write_text(texto, encoding="utf-8")

    area_de_trabalho = pasta_especial(None, "DESKTOP", Path.home() / "Desktop")
    area_de_trabalho.mkdir(parents=True, exist_ok=True)
    atalho = area_de_trabalho / "openems-lab.desktop"
    atalho.write_text(texto, encoding="utf-8")
    atalho.chmod(0o755)
    # o Cinnamon e o GNOME só abrem atalhos da Área de Trabalho marcados como confiáveis
    try:
        subprocess.run(["gio", "set", str(atalho), "metadata::trusted", "true"], capture_output=True)
    except OSError:
        pass
    return atalho


def preparar():
    notebooks = pasta_notebooks()
    novos = copiar_notebooks(notebooks)
    if novos:
        print(f"Notebooks novos copiados para {notebooks}:")
        for nome in novos:
            print(f"  - {nome}")
    atalho = criar_atalho()
    if atalho:
        print(f"Atalho na Área de Trabalho: {atalho.name}")
    return notebooks


def main():
    notebooks = preparar()
    if "--preparar" in sys.argv:
        return 0

    print()
    print("O Jupyter vai abrir no navegador em alguns segundos.")
    print("NÃO FECHE ESTA JANELA enquanto usa o Jupyter.")
    print("Para encerrar: salve os notebooks, feche o navegador e depois feche esta janela.")
    print()

    from jupyterlab.labapp import main as jupyter_lab

    sys.argv = ["jupyter-lab", f"--ServerApp.root_dir={notebooks}"]
    return jupyter_lab()


if __name__ == "__main__":
    sys.exit(main())
