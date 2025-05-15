#!/bin/bash


set -euo pipefail


VOL_PATH="/mnt/data/static-website"
HTML_PATH="$VOL_PATH/html"
MANIFEST_PATH="./k8sManifests"
WEB_REPO="https://github.com/BrunoRedolfi/static-website.git"
K8S_REPO="https://github.com/BrunoRedolfi/sitio-web-k8s.git"
BASE_DIR="${1:-$HOME/Documentos/k8s-web}" 
WEB_MOUNT_DIR="${BASE_DIR}/static-website"
K8S_DIR="${BASE_DIR}/k8s-manifests"
MOUNT_STRING="${WEB_MOUNT_DIR}:/mnt/data/static-website"
TMP_CLONE_DIR="$(mktemp -d)"
RESET="\e[0m"


#existe el comando?
comando_existe(){
  command -v "$1" >/dev/null 2>&1
}

#instalar docker si no lo esta
instalar_docker(){
  if comando_existe docker; then
    echo "Docker ya existe:"
    docker --version
    return
  fi
  echo "Instalando docker:"
  # Use Docker's convenience script
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            rm get-docker.sh
            
            # Add user to the docker group to run Docker without sudo
            sudo usermod -aG docker $USER
}

#instalar minikube si no lo esta
instalar_minikube(){
  if comando_existe minikube; then
    echo "Minikube ya existe:"
    minikube version 
    return
  fi 
  echo "Instalando minikube:"
  # Usar storage.googleapis para descargar minikube 
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
}
#instalar kubectl si no lo esta
instalar_kubectl(){
  if comando_existe kubectl; then
    echo "Kubectl ya existe:"
    return
  fi
    echo "Instalando kubectl:"
    #Latest
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
}
#borrar instancia si no es de docker
minikube_docker() {
    if minikube status &>/dev/null; then
        echo "⚠️ Ya existe una instancia de Minikube."
        echo "→ Montaje actual: ${MOUNT_STRING}"
        echo "Eliminando instancia previa de Minikube automáticamente..."
        minikube delete
    fi 
}




instalar_docker;
instalar_minikube;
instalar_kubectl;



# MINIKUBE
echo "Minikube:"
minikube_docker

echo "Preparando estructura de carpetas"
mkdir -p "$WEB_MOUNT_DIR"
rm -rf "$K8S_DIR"

echo "Clonando sitio web desde GitHub"
if ! git clone "$WEB_REPO" "$TMP_CLONE_DIR"; then
    echo "Fallo al clonar el repositorio del sitio web."
    exit 1
fi
cp -r "$TMP_CLONE_DIR"/* "$WEB_MOUNT_DIR"
rm -rf "$TMP_CLONE_DIR"

echo "Clonando manifiestos desde GitHub"
if ! git clone "$K8S_REPO" "$K8S_DIR"; then
    echo "Fallo al clonar el repositorio de manifiestos."
    exit 1
fi

echo "Iniciando Minikube con montaje de volumen local"
minikube start --mount --mount-string="${MOUNT_STRING}"

echo "📦 Aplicando los manifiestos de Kubernetes..."
echo "Aplicando manifiestos de Kubernetes"
find "$K8S_DIR" -type f -name "*.yaml" | while read -r yaml_file; do
    echo -e "Aplicando: $yaml_file${RESET}"
    kubectl apply -f "$yaml_file"
done

echo "Espere un minutito a que inicie la cosa:"
sleep 60

echo "✅ Despliegue completo. Verificando estado del servicio..."
minikube service sitio-web-service

