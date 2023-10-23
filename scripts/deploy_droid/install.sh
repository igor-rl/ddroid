#!/bin/bash

add_to_config() {
  local config_file=$1
  echo "alias ddroid='./scripts/deploy_droid/ddroid.sh'" >> $config_file
  echo "Alias 'ddroid' adicionado ao $config_file."
  echo
  echo
  echo "🤖 DDroid instalado com sucesso!"
  sleep 1
  echo
  echo
  echo "Para iniciar o '🤖 DDroid', execute o comando 'ddroid' no seu terminal."
  exec $SHELL
}

# Pergunta ao usuário se deseja adicionar o alias
clear
echo "Iniciando a instalação do 🤖 DDroid no seu projeto..."
sleep 4
if [[ $SHELL == *"zsh"* ]]; then
    add_to_config ~/.zshrc
elif [[ $SHELL == *"bash"* ]]; then
    add_to_config ~/.bashrc
else
    echo "Shell não reconhecido. O alias não foi adicionado automaticamente."
fi