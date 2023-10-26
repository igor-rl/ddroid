#!/bin/bash
DDROID_VERSION="1.0.11"

check_current_version() {
    if [ -f ~/bin/ddroid ]; then
        CURRENT_VERSION=$(~/bin/ddroid --version)
        if [ "$CURRENT_VERSION" != "$DDROID_VERSION" ]; then
            return 1  # Versions are different
        else
            return 0  # Versions are the same
        fi
    else
        return 1  # DDroid is not installed
    fi
}

echo "Instalando 🤖 DDroid v${DDROID_VERSION} no seu projeto..."
if ! command -v git &> /dev/null; then
    echo "Erro: git não está instalado."
    exit 1
fi

check_current_version
if [ $? -eq 1 ]; then
    # Clona o repositório
    curl -o ddroid.sh "https://raw.githubusercontent.com/igor-rl/ddroid/main/script/ddroid.sh?$(date +%s)"

    # Cria o diretório ~/bin se ele não existir
    mkdir -p ~/bin

    # Move o ddroid.sh para ~/bin e torna-o executável
    mv ddroid.sh ~/bin/ddroid
    chmod +x ~/bin/ddroid

    echo "🤖 DDroid v${DDROID_VERSION} instalado com sucesso!"
    sleep 1
    echo
    echo "Para iniciar o '🤖 DDroid', execute o comando 'ddroid' no seu terminal."

    # Verifica se ~/bin está no PATH. Se não estiver, adiciona ao .bashrc ou .zshrc
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        if [[ $SHELL == *"zsh"* ]]; then
            echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
        elif [[ $SHELL == *"bash"* ]]; then
            echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
        else
            echo "Shell não reconhecido. Ajuste manualmente o PATH se necessário."
        fi
    fi

    exec $SHELL
else
    echo "🤖 DDroid já está na versão mais recente ($DDROID_VERSION)."
fi
