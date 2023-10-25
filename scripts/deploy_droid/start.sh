#!/bin/bash

DB_PORTS=(4001 5432)
DB_PORTS=(4000 4000)

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
source ddroid.env

# DATABASE
if $RUN_DATABASE; then
    echo
    echo "📦  Iniciando configurações do ${DB_CONTAINER_NAME}..."
    echo "🤖  kubectl apply -f ${K8S_DB_FOLDER}"
    kubectl apply -f ${K8S_DB_FOLDER}
    while [[ $(kubectl get pods -l app=${DB_CONTAINER_NAME} -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
        echo
        echo "🤖  kubectl get pods -l app=${DB_CONTAINER_NAME}"
        kubectl get pods -l app=${DB_CONTAINER_NAME}
        sleep 5
    done
    echo
    echo "🤖  kubectl get pods -l app=${DB_CONTAINER_NAME} -o jsonpath='{.items[0].metadata.name}'"
    DB_POD=$(kubectl get pods -l app=${DB_CONTAINER_NAME} -o jsonpath='{.items[0].metadata.name}')
    echo "🤖  ${DB_POD}"
    echo
    echo "🤖  kubectl port-forward ${DB_POD} ${DB_PORTS[0]}:${DB_PORTS[1]} & echo $! > tmp/db-port-forward.pid"
    kubectl port-forward ${DB_POD} ${DB_PORTS[0]}:${DB_PORTS[1]} &
    echo $! > tmp/db-port-forward.pid
    echo
    echo "🤖  🔗 Port-forward em segundo plano ${DB_PORTS[0]}:${DB_PORTS[1]}"
    DB_ENDPOINT=$(kubectl get service ${K8S_DB_SERVICE_NAME} -o=jsonpath='{.spec.clusterIP}')
    echo
    echo "🤖  kubectl create configmap app-config --from-literal=instance_host=${DB_ENDPOINT} --dry-run=client -o yaml | kubectl apply -f -"
    kubectl create configmap app-config --from-literal=instance_host=${DB_ENDPOINT} --dry-run=client -o yaml | kubectl apply -f -
fi

# API
echo
echo "📦  Iniciando configurações da API..."
echo "🤖  kubectl apply -f ${K8S_API_FOLDER}"
kubectl apply -f ${K8S_API_FOLDER}
while [[ $(kubectl get pods -l app=${BACK_CONTAINER_NAME} -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    echo
    echo "🤖  kubectl get pods -l app=${BACK_CONTAINER_NAME}"
    kubectl get pods -l app=${BACK_CONTAINER_NAME}
    sleep 5
done
APP_POD=$(kubectl get pods -l app=${BACK_CONTAINER_NAME} -o jsonpath='{.items[0].metadata.name}')
if $RUN_MIGRATION; then
    echo
    echo "🤖  Executando migrações..."
    echo "🤖  kubectl exec ${APP_POD} -- npm run migration:run"
    kubectl exec ${APP_POD} -- npm run migration:run
fi
echo
echo "🤖  kubectl port-forward ${APP_POD} ${DB_PORTS[0]}:${DB_PORTS[1]} & echo $! > tmp/app-port-forward.pid"
kubectl port-forward ${APP_POD} ${DB_PORTS[0]}:${DB_PORTS[1]} &
echo $! > tmp/app-port-forward.pid
echo
echo "🤖  🔗 Port-forward do ${BACK_CONTAINER_NAME} em segundo plano ${DB_PORTS[0]}:${DB_PORTS[1]}"
echo
echo "🤖  ✅ Deploy concluído!"
echo
echo "🤖  kubectl logs -f $APP_POD"
kubectl logs -f $APP_POD
