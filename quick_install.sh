#!/bin/bash

if ! command -v git &> /dev/null; then
    echo "Erro: git não está instalado."
    exit 1
fi
mkdir -p scripts/deploy_droid
git clone https://github.com/igor-rl/ddroid.git
mv ddroid/scripts/deploy_droid/* scripts/deploy_droid
rm -rf ddroid
bash ./scripts/deploy_droid/install.sh
