#!/bin/bash

echo -n "🤖⚠️  Deseja mesmo continuar? Todo o cluster será perdido! [s/N]:"
read -r response
if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
    echo "🤖😢  goodbye!"
    sleep 3
    source ./scripts/stop.sh
    minikube delete --all
    echo "⚰️  Se foi!"
    exit
fi
echo "🤖  Operação cancelada."
