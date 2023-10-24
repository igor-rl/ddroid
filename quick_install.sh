#!/bin/bash

if ! command -v git &> /dev/null; then
    echo "Erro: git não está instalado."
    exit 1
fi
mkdir -p scripts/deploy_droid
git clone https://github.com/igor-rl/ddroid.git
mv ddroid/scripts/deploy_droid/* scripts/deploy_droid
rm -rf ddroid
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
}
echo "Iniciando a instalação do 🤖 DDroid no seu projeto..."
sleep 4
# if [[ $SHELL == *"zsh"* ]]; then
#     add_to_config ~/.zshrc
# elif [[ $SHELL == *"bash"* ]]; then
#     add_to_config ~/.bashrc
# else
#     echo "Shell não reconhecido. O alias não foi adicionado automaticamente."
# fi
# exec $SHELL
