#!/bin/bash

if ! command -v git &> /dev/null; then
    echo "Erro: git não está instalado."
    exit 1
fi
mkdir -p scripts/deploy_droid
git clone https://github.com/igor-rl/ddroid.git scripts/deploy_droid/temp
mv scripts/deploy_droid/temp/scripts/* scripts/deploy_droid
rm -rf scripts/deploy_droid/temp
# bash scripts/deploy_droid/install.sh
