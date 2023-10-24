#!/bin/bash

remove_from_config() {
    local config_file=$1
    # if grep -q "alias ddroid='./scripts/deploy_droid/ddroid.sh'" $config_file; then
        sed -i '/alias ddroid/d' $config_file
        echo "Alias 'ddroid' removido de $config_file."
    # else
        # echo "Alias 'ddroid' não encontrado em $config_file."
    # fi
}

remove_ddroid_directory() {
    if [ -d "scripts/deploy_droid" ]; then
        rm -rf scripts/deploy_droid
        echo "Diretório 'ddroid' removido com sucesso!"
    else
        echo "Diretório 'ddroid' não encontrado!"
    fi
}

clear
echo -n "🤖 Remover o DDroid do seu projeto? [s/N]:"
read -r response
if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
    echo "🤖🔫"
    sleep 2
    if [[ $SHELL == *"zsh"* ]]; then
        remove_from_config ~/.zshrc
        unalias ddroid 2>/dev/null
    elif [[ $SHELL == *"bash"* ]]; then
        remove_from_config ~/.bashrc
        unalias ddroid 2>/dev/null
    else
        echo "Shell não reconhecido. Não foi possível remover o alias automaticamente."
    fi

    remove_ddroid_directory

    echo
    echo "⚰️  DDroid foi desinstalado com sucesso!"
    exec $SHELL

else
    echo "Desinstalação cancelada."
    exit 0
fi
