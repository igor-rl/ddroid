#!/bin/bash

DDROID_VERSION="1.0.21"
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
  DIRETORIO=k8s
}

load_or_create_env() {
  if [ ! -f ddroid.env ]; then
    echo "DOCKER_HUB_USER=" >> ddroid.env
    echo "DOCKER_HUB_IMAGE=" >> ddroid.env
    echo "DB_CONTAINER_NAME=none" > ddroid.env
    echo "DB_VOLUME=./db/mysql" >> ddroid.env
    echo "BACK_CONTAINER_NAME=none" >> ddroid.env
  fi
}


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
    echo "🤖 DDroid ${DDROID_VERSION}"
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
  options=("🚀  kubectl apply" "🗑️   kubectl delete" "🧨  Destruir projeto" "🔙  Voltar")
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
        0) KBS_OPTIONS=start; break ;;
        1) KBS_OPTIONS=stop; break ;;
        2) KBS_OPTIONS=destroi; break ;;
        3) voltar; break ;;
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

get_directories() {
  find ${DIRETORIO}/ -maxdepth 1 -mindepth 1 -type d
}

print_menu() {
  for i in "${!options[@]}"; do
    if [[ "$i" -eq $CURSOR_POSITION ]]; then
      echo -e "${CURSOR} ${options[$i]}"
    else
      echo -e "  ${options[$i]}"
    fi
  done
}

selecionarDiretorios() {
  if [ ! -d "k8s/" ]; then
    echo "🤖  A pasta k8s não existe."
    exit 0
  fi
  CURSOR_POSITION=0
  while true; do

    NUM=$(find ${DIRETORIO} -maxdepth 1 -name "*.yaml" -o -name "*.yml" | wc -l)
    WORD=''
    # Fazer uma declaração if com o resultado
    if [ $NUM -gt 0 ]; then
      if [ $NUM -gt 0 ]; then
        WORD=s
      fi
      echo "🤖  Aplicando $NUM manifesto$WORD."
      break
    fi

    directories=($(get_directories))
    options=("${directories[@]}")
    options+=("todos")
    clear
    echo -e "\e[1m📂  Diretórios encontrados:\e[0m"
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
      if [[ "$CURSOR_POSITION" -eq $((${#options[@]}-1)) ]]; then
        break
      else
        DIRETORIO=${options[$CURSOR_POSITION]}
        CURSOR_POSITION=0
      fi
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

verificarMinikube(){
  status=$(minikube status 2>&1)
  if [[ $status == *"host: Running"* ]]; then
    echo "🤖  Minikube já está em execução."
  else
    echo "🤖  Iniciando o Minikube..."
    minikube start
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
  verificarMinikube
  selecionarDiretorios
  for file in $(find ${DIRETORIO} -type f \( -name "*.yml" -o -name "*.yaml" \)); do
    echo "🤖  kubectl apply -f $file"
    kubectl apply -f $file
  done
  
  clear

  SERVICES=$(kubectl get services -o jsonpath='{.items[*].metadata.name}')
  for SERVICE in $SERVICES; do

    PORT_FORWARD_NAME="${SERVICE^^}_PORT_FORWARD"
    eval "PORT_FORWARD_VALUES=(\${$PORT_FORWARD_NAME[@]})"

    if [[ ${#PORT_FORWARD_VALUES[@]} -gt 0 ]]; then
      if [ ! -f "tmp/$SERVICE-port-forward.pid" ]; then
        while [[ $(kubectl get pods -l app=${SERVICE} -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
          echo
          echo "🤖  kubectl get pods -l app=${SERVICE}"
          kubectl get pods -l app=${SERVICE}
          sleep 5
        done
        kubectl port-forward svc/${SERVICE} ${PORT_FORWARD_VALUES[0]}:${PORT_FORWARD_VALUES[1]} &
        [ ! -d "tmp" ] && mkdir "tmp"
        echo $! > tmp/db-port-forward.pid
        echo
        echo "🤖  🔗 Port-forward do ${SERVICE} em segundo plano ${PORT_FORWARD_VALUES[0]}:${PORT_FORWARD_VALUES[1]}"
        echo
      fi
    fi
  done
  echo
  echo "🤖  ✅ Deploy concluído!"
}

k8sDelete(){
  echo

  verificarMinikube
  selecionarDiretorios
  for file in $(find ${DIRETORIO} -type f \( -name "*.yml" -o -name "*.yaml" \)); do
    echo "🤖  🚀  kubectl delete -f $file"
    kubectl delete -f $file
  done

  for file in tmp/*-port-forward.pid; do
    PID=$(cat "$file")
    echo "🤖  Matando processo com PID $PID..."
    kill "$PID"
    rm ${file}
  done

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

source ddroid.env

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
