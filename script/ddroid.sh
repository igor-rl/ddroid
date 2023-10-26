#!/bin/bash

DDROID_VERSION="1.0.18"
CURSOR=">"
RUN_MIGRATION=false
RUN_DATABASE=false

if [ "$1" == "--version" ]; then
  echo "$DDROID_VERSION"
  exit 0
fi

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

unsetVars(){
  CURSOR_POSITION=0
  AMBIENTE=none
  TESTE=none
  LOCAL_OPTIONS=none
  DOCKER_OPTIONS=none
  KBS_OPTIONS=none
}

load_or_create_env() {
  if [ ! -f ddroid.env ]; then
    # Se ddroid.env não existe, cria e preenche com valores padrão
    echo "# Docker" > ddroid.env
    echo "DOCKER_HUB_USER=" >> ddroid.env
    echo "DOCKER_HUB_IMAGE=" >> ddroid.env
    echo "DB_CONTAINER_NAME=none" > ddroid.env
    echo "DB_VOLUME=./db/mysql" >> ddroid.env
    echo "BACK_CONTAINER_NAME=none" >> ddroid.env
    echo "" > ddroid.env
    echo "# k8s" > ddroid.env
    echo "K8S_DB_PORTS=(80 80)" >> ddroid.env
    echo "K8S_APP_PORTS=(80 80)" >> ddroid.env
    echo "" > ddroid.env
    echo "K8S_DB_FOLDER=" >> ddroid.env
    echo "K8S_DB_POD_NAME=" >> ddroid.env
    echo "K8S_DB_SERVICE_NAME=" >> ddroid.env
    echo "K8S_API_FOLDER=" >> ddroid.env
    echo "K8S_API_POD_NAME=" >> ddroid.env
    echo "K8S_API_SERVICE_NAME=" >> ddroid.env
  fi
  # Carrega as variáveis do arquivo ddroid.env
  source ddroid.env
}

# Analise os argumentos
for arg in "$@"; do
    case $arg in
        --migration=true)
            RUN_MIGRATION=true
            ;;
        --ambiente=docker)
            AMBIENTE=docker
            ;;
        --ambiente=k8s)
            AMBIENTE=k8s
            ;;
        --teste=prod)
            TESTE=prod
            ;;
    esac
done

defineAmbiente(){
  options=("🏠  Local" "🐳  Docker" "⚓  Kubernetes" "⚰️   Desinstalar DDroid" "🚪  Sair")
  print_menu() {
    for i in "${!options[@]}"; do
      if [[ "$i" -eq $CURSOR_POSITION ]]; then
        echo -e "${CURSOR} ${options[$i]}"
      else
        echo -e "  ${options[$i]}"
      fi
    done
  }
  while true; do
    clear
    echo "🤖 DDroid ${CURRENT_VERSION}"
    echo
    echo "Como deseja implantar sua aplicação?"
    print_menu
    read -rsn3 key
    if [[ $key == $'\x1b[A' ]]; then
      if [[ "$CURSOR_POSITION" -gt 0 ]]; then
        CURSOR_POSITION=$((CURSOR_POSITION-1))
      fi
    elif [[ $key == $'\x1b[B' ]]; then
      if [[ "$CURSOR_POSITION" -lt $((${#options[@]}-1)) ]]; then
        CURSOR_POSITION=$((CURSOR_POSITION+1))
      fi
    elif [[ $key == "" ]]; then
      clear
      case $CURSOR_POSITION in
        0) echo "🏠  Executando teste local..."; AMBIENTE=local; break ;;
        1) echo "🐳  Executando teste com docker..."; AMBIENTE=docker; break ;;
        2) echo "⚓  Executando teste com kubernetes..."; AMBIENTE=k8s; break ;;
        3) echo "🤖  Desinstalar DDroid..."; uninstall; exit;;
        4) echo "🤖👋  Até logo!"; exit ;;
      esac
    fi
  done
}

localOptions(){
  CURSOR_POSITION=0
  options=("🚀  Executar projeto local" "🗑️   Limpar projeto local" "🔙  Voltar")
  print_menu() {
    for i in "${!options[@]}"; do
      if [[ "$i" -eq $CURSOR_POSITION ]]; then
        echo -e "${CURSOR} ${options[$i]}"
      else
        echo -e "  ${options[$i]}"
      fi
    done
  }
  while true; do
    clear
    echo -e "\e[1m🤖  Opçoes para ambiente 🏠  Local:\e[0m"
    print_menu
    read -rsn3 key
    if [[ $key == $'\x1b[A' ]]; then
      if [[ "$CURSOR_POSITION" -gt 0 ]]; then
        CURSOR_POSITION=$((CURSOR_POSITION-1))
      fi
    elif [[ $key == $'\x1b[B' ]]; then
      if [[ "$CURSOR_POSITION" -lt $((${#options[@]}-1)) ]]; then
        CURSOR_POSITION=$((CURSOR_POSITION+1))
      fi
    elif [[ $key == "" ]]; then
      clear
      case $CURSOR_POSITION in
        0) LOCAL_OPTIONS=start; break ;;
        1) LOCAL_OPTIONS=clean; break ;;
        2) voltar; break ;;
      esac
    fi
  done
}

KbsOptions(){
  CURSOR_POSITION=0
  options=("🚀  Iniciar com Minikube" "⚓  Deploy k8s" "🗑️   Deletar deploys" "🧨  Destruir projeto" "🔙  Voltar")
  print_menu() {
    for i in "${!options[@]}"; do
      if [[ "$i" -eq $CURSOR_POSITION ]]; then
        echo -e "${CURSOR} ${options[$i]}"
      else
        echo -e "  ${options[$i]}"
      fi
    done
  }
  while true; do
    clear
    echo -e "\e[1m🤖  Opçoes com K8s⚓:\e[0m"
    print_menu
    read -rsn3 key
    if [[ $key == $'\x1b[A' ]]; then
      if [[ "$CURSOR_POSITION" -gt 0 ]]; then
        CURSOR_POSITION=$((CURSOR_POSITION-1))
      fi
    elif [[ $key == $'\x1b[B' ]]; then
      if [[ "$CURSOR_POSITION" -lt $((${#options[@]}-1)) ]]; then
        CURSOR_POSITION=$((CURSOR_POSITION+1))
      fi
    elif [[ $key == "" ]]; then
      clear
      case $CURSOR_POSITION in
        0) KBS_OPTIONS=init; break ;;
        1) KBS_OPTIONS=start; break ;;
        2) KBS_OPTIONS=stop; break ;;
        3) KBS_OPTIONS=destroi; break ;;
        4) voltar; break ;;
      esac
    fi
  done
}

dockerOptions(){
  CURSOR_POSITION=0
  options=("🚀  Teste dev" "🚀  Teste producao" "🗑️   Deletar containers do projeto" "🧨  Destruir tudo" "🔙  Voltar")

  print_menu() {
    for i in "${!options[@]}"; do
      if [[ "$i" -eq $CURSOR_POSITION ]]; then
        echo -e "${CURSOR} ${options[$i]}"
      else
        echo -e "  ${options[$i]}"
      fi
    done
  }
  while true; do
    clear
    echo -e "\e[1m🤖  Opçoes com Docker🐳:\e[0m"
    print_menu
    read -rsn3 key
    if [[ $key == $'\x1b[A' ]]; then
      if [[ "$CURSOR_POSITION" -gt 0 ]]; then
        CURSOR_POSITION=$((CURSOR_POSITION-1))
      fi
    elif [[ $key == $'\x1b[B' ]]; then
      if [[ "$CURSOR_POSITION" -lt $((${#options[@]}-1)) ]]; then
        CURSOR_POSITION=$((CURSOR_POSITION+1))
      fi
    elif [[ $key == "" ]]; then
      clear
      case $CURSOR_POSITION in
        0) DOCKER_OPTIONS=dev; break ;;
        1) DOCKER_OPTIONS=prod; break ;;
        2) DOCKER_OPTIONS=down; break ;;
        3) DOCKER_OPTIONS=prune; break ;;
        4) voltar; break ;;
      esac
    fi
  done
}

verificarInstalacao() {
  if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
    echo "🤖  npm install"
    npm install
  fi
  echo "🤖  dependencias do projeto instaladas"
}

verificarDesistalacao() {
  if [ -d "node_modules" ]; then
    echo -n "🤖❓ Excluir a node_modules? [s/N]:"
    read -r response
    if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
      echo "🤖  sudo rm -rf ./node_modules"
      sudo rm -rf ./node_modules
    fi
  fi
}

verificaBanco(){
  if docker ps --format '{{.Names}}' | grep -q "${DB_CONTAINER_NAME}"; then
    echo "🤖  DB ${DB_CONTAINER_NAME} já está ativo."
  else
    echo "🤖  DB ${DB_CONTAINER_NAME} não está ativo. Iniciando..."
    echo "🤖  docker compose up -d ${DB_CONTAINER_NAME}"
    docker compose up -d ${DB_CONTAINER_NAME}
  fi
}

verificaMigration(){
  echo
  echo -n "🤖❓ Atualizar as migrações? [s/N]:"
  read -r response
  if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
      echo "🤖  npm run migration:run"
      npm run migration:run
  fi
}

verificarBuild(){
  IMAGE_NAME=$(grep "image: docker.io/${DOCKER_HUB_USER}/${DOCKER_HUB_IMAGE}" ./docker-compose-prod.yaml | awk '{print $2}')
  echo "veririfcar imagem ${IMAGE_NAME}"
  IMAGE_REPO=$(echo $IMAGE_NAME | awk -F: '{print $1}')
  IMAGE_TAG=$(echo $IMAGE_NAME | awk -F: '{print $2}')
  if [ -z "$IMAGE_TAG" ]; then
      IMAGE_TAG="latest"
  fi
  IMAGE_REPO=$(echo $IMAGE_REPO | sed 's/docker.io\///g')
  EXISTS=$(curl -so /dev/null -w "%{http_code}" https://hub.docker.com/v2/repositories/$IMAGE_REPO/tags/$IMAGE_TAG)

  if [ "$EXISTS" == "200" ]; then
      echo "🤖 Imagem existente no Docker Hub!"
  else
      echo "🤖 A imagem não existe no Docker Hub. Construindo..."
      echo "🤖 docker build -t ${IMAGE_NAME} -f Dockerfile.prod ."
      docker build -t ${IMAGE_NAME} -f Dockerfile.prod .
      echo "🤖 docker push ${IMAGE_NAME}"
      docker push ${IMAGE_NAME}
      # criar a imagem latest
      if [ "$IMAGE_TAG" != "latest" ]; then
        docker tag ${IMAGE_REPO}:${IMAGE_TAG} ${IMAGE_REPO}:latest
        docker push ${IMAGE_REPO}:latest
      fi
  fi
}

localDev(){
  verificarInstalacao
  verificaBanco
  verificaMigration
  echo "🤖  npm run start:dev"
  sleep 3
  npm run start:dev
}

localClean(){
  echo
  echo -n "🤖❓ Limpar o banco de dados local? Todos os dados serão perdidos! [s/N]:"
  read -r response
  if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
      echo "🤖  docker compose down $DB_CONTAINER_NAME"
      docker compose down $DB_CONTAINER_NAME
      echo "🗑️   sudo rm -rf $DB_VOLUME"
      sudo rm -rf $DB_VOLUME
  fi
  echo

  verificarDesistalacao
  echo "🗑️   sudo rm -rf package-lock.json .npm-cache .wwebjs_auth .wwebjs_cache dist tmp"
  sudo rm -rf package-lock.json .npm-cache .wwebjs_auth .wwebjs_cache dist tmp
  exit
}

dockerProd(){
  echo -e "\e[1m🐳 Docker - Teste simulando imagem de produção\e[0m"
  verificarBuild
  echo "🤖  docker compose -f docker-compose-prod.yaml up -d"
  docker compose -f docker-compose-prod.yaml up -d
  verificaMigration
  echo "🤖  docker logs $BACK_CONTAINER_NAME -f"
  docker logs $BACK_CONTAINER_NAME -f 
  exit
}

dockerDev(){
  echo -e "\e[1m🐳 Docker - Teste em ambiente de desenvolvimento\e[0m"
  echo "🤖  docker compose up -d"
  docker compose up -d
  verificarInstalacao
  verificaMigration
  echo "🤖  docker exec -it $BACK_CONTAINER_NAME /bin/sh -c 'npm run start:dev'"
  echo "🤖  docker logs $BACK_CONTAINER_NAME -f"
  docker exec -it $BACK_CONTAINER_NAME /bin/sh -c "npm run start:dev"
  docker logs $BACK_CONTAINER_NAME -f
  exit
}

dockerDown(){
  echo "🤖  docker compose down"
  docker compose down
  exit
}

dockerPrune(){
  echo
  echo -n "⚠️🤖❓  Deseja mesmo continuar? Todos os dados do Docker 🐳 serão perdido! [s/N]:"
  read -r response
  if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
      echo "🤖  docker system prune -a"
      exit
  fi
  echo "🤖  Operação cancelada."
}

k8sApply(){
  echo "🤖  Iniciando deploy"
  source ddroid.env

  # DATABASE
  echo
  echo "📦  Iniciando configurações do ${K8S_DB_POD_NAME}..."
  echo "🤖  kubectl apply -f ${K8S_DB_FOLDER}"
  kubectl apply -f ${K8S_DB_FOLDER}
  while [[ $(kubectl get pods -l app=${K8S_DB_POD_NAME} -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    echo
    echo "🤖  kubectl get pods -l app=${K8S_DB_POD_NAME}"
    kubectl get pods -l app=${K8S_DB_POD_NAME}
    sleep 5
  done
  echo
  echo "🤖  kubectl get pods -l app=${K8S_DB_POD_NAME} -o jsonpath='{.items[0].metadata.name}'"
  DB_POD=$(kubectl get pods -l app=${K8S_DB_POD_NAME} -o jsonpath='{.items[0].metadata.name}')
  echo "🤖  ${DB_POD}"
  echo
  echo "🤖  kubectl port-forward ${DB_POD} ${K8S_DB_PORTS[0]}:${K8S_DB_PORTS[1]} & echo $! > tmp/db-port-forward.pid"
  kubectl port-forward ${DB_POD} ${K8S_DB_PORTS[0]}:${K8S_DB_PORTS[1]} &
  echo $! > tmp/db-port-forward.pid
  echo
  echo "🤖  🔗 Port-forward em segundo plano ${K8S_DB_PORTS[0]}:${K8S_DB_PORTS[1]}"
  DB_ENDPOINT=$(kubectl get service ${K8S_DB_SERVICE_NAME} -o=jsonpath='{.spec.clusterIP}')
  echo
  echo "🤖  kubectl create configmap ${K8S_API_POD_NAME}-config --from-literal=instance_host=${DB_ENDPOINT} --dry-run=client -o yaml | kubectl apply -f -"
  kubectl create configmap ${K8S_API_POD_NAME}-config --from-literal=instance_host=${DB_ENDPOINT} --dry-run=client -o yaml | kubectl apply -f -

  # API
  echo
  echo "📦  Iniciando configurações da API..."
  echo "🤖  kubectl apply -f ${K8S_API_FOLDER}"
  kubectl apply -f ${K8S_API_FOLDER}
  while [[ $(kubectl get pods -l app=${K8S_API_POD_NAME} -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    echo
    echo "🤖  kubectl get pods -l app=${K8S_API_POD_NAME}"
    kubectl get pods -l app=${K8S_API_POD_NAME}
    sleep 5
  done
  APP_POD=$(kubectl get pods -l app=${K8S_API_POD_NAME} -o jsonpath='{.items[0].metadata.name}')
  echo
  echo -n "🤖❓ Atualizar as migrações? [s/N]:"
  read -r response
  if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
    echo
    echo "🤖  Executando migrações..."
    echo "🤖  kubectl exec ${APP_POD} -- npm run migration:run"
    kubectl exec ${APP_POD} -- npm run migration:run
  fi
  echo
  echo "🤖  kubectl port-forward ${APP_POD} ${K8S_APP_PORTS[0]}:${K8S_APP_PORTS[1]} & echo $! > tmp/app-port-forward.pid"
  kubectl port-forward ${APP_POD} ${K8S_APP_PORTS[0]}:${K8S_APP_PORTS[1]} &
  echo $! > tmp/app-port-forward.pid
  echo
  echo "🤖  🔗 Port-forward do ${BACK_CONTAINER_NAME} em segundo plano ${K8S_APP_PORTS[0]}:${K8S_APP_PORTS[1]}"
  echo
  echo "🤖  ✅ Deploy concluído!"
  echo
  echo "🤖  kubectl logs -f $APP_POD"
  kubectl logs -f $APP_POD
}

k8sDelete(){
  echo
  echo "🤖  🚀  Encerrando projeto"
  if [ -f tmp/db-port-forward.pid ]; then
      PID=$(cat tmp/db-port-forward.pid)
      kill $PID
      echo "🤖  rm tmp/db-port-forward.pid"
      rm tmp/db-port-forward.pid
      echo "🤖  🛑  processo port-forward do ${DB_CONTAINER_NAME} com PID $PID foi interrompido."
  else
      echo "🤖  ⚠️  arquivo db-port-forward.pid não encontrado. Parece que o port-forward do ${DB_CONTAINER_NAME} não foi iniciado por este script."
  fi
  if [ -f tmp/app-port-forward.pid ]; then
      PID=$(cat tmp/app-port-forward.pid)
      kill $PID
      echo "🤖  rm tmp/app-port-forward.pid"
      rm tmp/app-port-forward.pid
      echo "🤖  🛑  processo port-forward do ${BACK_CONTAINER_NAME} com PID $PID foi interrompido."
  else
      echo "🤖  ⚠️  arquivo app-port-forward.pid não encontrado. Parece que o port-forward do ${BACK_CONTAINER_NAME} não foi iniciado por este script."
  fi
  echo
  echo "🤖  🗑️  kubectl delete -f ${K8S_DB_FOLDER}"
  kubectl delete -f ${K8S_DB_FOLDER}
  echo
  echo "🤖  🗑️  kubectl delete -f ${K8S_API_FOLDER}"
  kubectl delete -f ${K8S_API_FOLDER}
  echo
  echo "🤖  🗑️  kubectl delete configmap ${K8S_API_POD_NAME}-config"
  kubectl delete configmap ${K8S_API_POD_NAME}-config
  echo
  echo "🤖  ✅ projeto encerrado"
}

k8sDestroy(){
  echo -n "🤖⚠️  Deseja mesmo continuar? Todo o cluster será perdido! [s/N]:"
  read -r response
  if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
      k8sDelete
      echo "🤖  minikube delete --all"
      sleep 3
      minikube delete --all
      exit
  fi
  echo "🤖  Operação cancelada."
}

uninstall(){
  echo -n "🤖  Remover o DDroid do seu projeto? [s/N]:"
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
}

load_or_create_env

while true; do

  unsetVars

  if [ "$AMBIENTE" = "none" ]; then
    defineAmbiente
  fi

  if [ "$AMBIENTE" = "local" ]; then
    localOptions
    case $LOCAL_OPTIONS in
      start)
        localDev
        ;;
      clean)
        localClean
        ;;
    esac
  fi

  if [ "$AMBIENTE" = "docker" ]; then
    dockerOptions
    case $DOCKER_OPTIONS in
      dev)
        dockerDev
        ;;
      prod)
        dockerProd
        ;;
      down)
        dockerDown
        ;;
      prune)
        dockerPrune
        ;;
    esac
  fi

  if [ "$AMBIENTE" = "k8s" ]; then
    KbsOptions
    case $KBS_OPTIONS in
      init)
        echo "🤖  minikube start"
        minikube start
        k8sApply;
        exit;;
      start)
        k8sApply;
        exit;;
      stop)
        k8sDelete;
        exit;;
      destroi)
        k8sDestroy;
        exit;;
    esac
  fi
done