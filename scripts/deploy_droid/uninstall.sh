#!/bin/bash

clear
echo -n "🤖 Remover o DDroid do seu projeto? [s/N]:"
read -r response
if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
    echo
    echo "🤖🔫 ..."
    echo
    sleep 2

    # Remove o script ddroid de ~/bin
    if [ -f ~/bin/ddroid ]; then
        rm ~/bin/ddroid
        # echo "Script ddroid removido com sucesso de ~/bin!"
    else
        echo "Script ddroid não encontrado em ~/bin!"
    fi

    echo
    echo "⚰️  DDroid foi desinstalado com sucesso!"
    exec $SHELL
else
    echo "Desinstalação cancelada."
    exit 0
fi
