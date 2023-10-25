#!/bin/bash

echo
echo "🤖  🚀  Encerrando projeto"

if [ -f tmp/db-port-forward.pid ]; then
    PID=$(cat tmp/db-port-forward.pid)
    kill $PID
    echo "🤖  rm tmp/db-port-forward.pid"
    rm tmp/db-port-forward.pid
    echo "🤖  🛑  processo port-forward do Postgres com PID $PID foi interrompido."
else
    echo "🤖  ⚠️  arquivo db-port-forward.pid não encontrado. Parece que o port-forward do Postgres não foi iniciado por este script."
fi

if [ -f tmp/app-port-forward.pid ]; then
    PID=$(cat tmp/app-port-forward.pid)
    kill $PID
    echo "🤖  rm tmp/app-port-forward.pid"
    rm tmp/app-port-forward.pid
    echo "🤖  🛑  processo port-forward do WhatsApp com PID $PID foi interrompido."
else
    echo "🤖  ⚠️  arquivo app-port-forward.pid não encontrado. Parece que o port-forward do WhatsApp não foi iniciado por este script."
fi
echo
echo "🤖  🗑️  kubectl delete -f k8s/postgreSql"
kubectl delete -f k8s/postgreSql
echo
echo "🤖  🗑️  kubectl delete -f k8s/whatsapp"
kubectl delete -f k8s/whatsapp
echo
echo "🤖  🗑️  kubectl delete configmap app-config"
kubectl delete configmap app-config
echo
echo "🤖  ✅ projeto encerrado"
