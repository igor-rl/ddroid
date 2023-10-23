#!/bin/bash

POSTGRES_PORTS=(4001 5432)
WHATSAPP_PORTS=(4000 4000)

RUN_MIGRATION=false
RUN_DATABASE=false

# Analise os argumentos
for arg in "$@"; do
    case $arg in
        --migration=true)
            RUN_MIGRATION=true
            ;;
        --database=true)
            RUN_DATABASE=true
            ;;
    esac
done

echo "🤖  Iniciando deploy"

# DATABASE
if $RUN_DATABASE; then
    echo
    echo "📦  Iniciando configurações do Postgres..."
    echo "🤖  kubectl apply -f k8s/postgreSql"
    kubectl apply -f k8s/postgreSql
    while [[ $(kubectl get pods -l app=postgres -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
        echo
        echo "🤖  kubectl get pods -l app=postgres"
        kubectl get pods -l app=postgres
        sleep 5
    done
    echo
    echo "🤖  kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}'"
    POSTGRES_POD=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')
    echo "🤖  $POSTGRES_POD"
    echo
    echo "🤖  kubectl port-forward $POSTGRES_POD ${POSTGRES_PORTS[0]}:${POSTGRES_PORTS[1]} & echo $! > tmp/postgres-port-forward.pid"
    kubectl port-forward $POSTGRES_POD ${POSTGRES_PORTS[0]}:${POSTGRES_PORTS[1]} &
    echo $! > tmp/postgres-port-forward.pid
    echo
    echo "🤖  🔗 Port-forward em segundo plano ${POSTGRES_PORTS[0]}:${POSTGRES_PORTS[1]}"
    POSTGRES_ENDPOINT=$(kubectl get service postgres -o=jsonpath='{.spec.clusterIP}')
    echo
    echo "🤖  kubectl create configmap whatsapp-config --from-literal=instance_host=$POSTGRES_ENDPOINT --dry-run=client -o yaml | kubectl apply -f -"
    kubectl create configmap whatsapp-config --from-literal=instance_host=$POSTGRES_ENDPOINT --dry-run=client -o yaml | kubectl apply -f -
fi

# API
echo
echo "📦  Iniciando configurações da API..."
echo "🤖  kubectl apply -f k8s/whatsapp"
kubectl apply -f k8s/whatsapp
while [[ $(kubectl get pods -l app=whatsapp-back -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    echo
    echo "🤖  kubectl get pods -l app=whatsapp-back"
    kubectl get pods -l app=whatsapp-back
    sleep 5
done
WHATSAPP_POD=$(kubectl get pods -l app=whatsapp-back -o jsonpath='{.items[0].metadata.name}')
if $RUN_MIGRATION; then
    echo
    echo "🤖  Executando migrações..."
    echo "🤖  kubectl exec $WHATSAPP_POD -- npm run migration:run"
    kubectl exec $WHATSAPP_POD -- npm run migration:run
fi
echo
echo "🤖  kubectl port-forward $WHATSAPP_POD ${WHATSAPP_PORTS[0]}:${WHATSAPP_PORTS[1]} & echo $! > tmp/whatsapp-port-forward.pid"
kubectl port-forward $WHATSAPP_POD ${WHATSAPP_PORTS[0]}:${WHATSAPP_PORTS[1]} &
echo $! > tmp/whatsapp-port-forward.pid
echo
echo "🤖  🔗 Port-forward do WhatsApp em segundo plano ${WHATSAPP_PORTS[0]}:${WHATSAPP_PORTS[1]}"
echo
echo "🤖  ✅ Deploy concluído!"
echo
echo "🤖  kubectl logs -f $WHATSAPP_POD"
kubectl logs -f $WHATSAPP_POD
