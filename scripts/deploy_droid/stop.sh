#!/bin/bash

echo
echo "🤖  🚀  Encerrando projeto"

if [ -f tmp/postgres-port-forward.pid ]; then
    PID=$(cat tmp/postgres-port-forward.pid)
    kill $PID
    echo "🤖  rm tmp/postgres-port-forward.pid"
    rm tmp/postgres-port-forward.pid
    echo "🤖  🛑  processo port-forward do Postgres com PID $PID foi interrompido."
else
    echo "🤖  ⚠️  arquivo postgres-port-forward.pid não encontrado. Parece que o port-forward do Postgres não foi iniciado por este script."
fi

if [ -f tmp/whatsapp-port-forward.pid ]; then
    PID=$(cat tmp/whatsapp-port-forward.pid)
    kill $PID
    echo "🤖  rm tmp/whatsapp-port-forward.pid"
    rm tmp/whatsapp-port-forward.pid
    echo "🤖  🛑  processo port-forward do WhatsApp com PID $PID foi interrompido."
else
    echo "🤖  ⚠️  arquivo whatsapp-port-forward.pid não encontrado. Parece que o port-forward do WhatsApp não foi iniciado por este script."
fi
echo
echo "🤖  🗑️  kubectl delete -f k8s/postgreSql"
kubectl delete -f k8s/postgreSql
echo
echo "🤖  🗑️  kubectl delete -f k8s/whatsapp"
kubectl delete -f k8s/whatsapp
echo
echo "🤖  🗑️  kubectl delete configmap whatsapp-config"
kubectl delete configmap whatsapp-config
echo
echo "🤖  ✅ projeto encerrado"
