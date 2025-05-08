#!/bin/bash

set -e

VOL_PATH="/mnt/data/static-website"
HTML_PATH="$VOL_PATH/html"
MANIFEST_PATH="./k8sManifests"



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
    kubectl version
    return
  fi
    echo "Instalando kubectl:"
    #Latest
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
}
instalar_docker;
instalar_minikube;
instalar_kubectl;

# MINIKUBE
# Detectar el driver actual
DRIVER=$(minikube config get driver 2>/dev/null || echo "docker")

echo "🔍 Minikube está usando el driver: $DRIVER"

if [ "$DRIVER" != "docker" ]; then
  echo "🧠 Detectado driver basado en VM ($DRIVER)"
  echo "🔍 Verificando que $HTML_PATH esté accesible dentro de Minikube..."
  if ! minikube ssh "test -d $HTML_PATH"; then
    echo "❌ ERROR: El directorio $HTML_PATH no está montado dentro de Minikube."
    echo "💡 Ejecutá este comando en otra terminal antes de continuar:"
    echo "    minikube mount /opt/projects/static-website:/mnt/data/static-website"
    exit 1
  fi
else
  echo "🎉 Driver 'docker' detectado. No es necesario usar 'minikube mount'."
fi

echo "📁 Creando carpeta local para archivos del sitio en $HTML_PATH (requiere sudo)..."
sudo mkdir -p "$HTML_PATH"

echo "🧹 Limpiando contenido previo del volumen..."
sudo rm -rf "$HTML_PATH"/*

echo "📄 Copiando archivos del sitio al volumen..."
sudo cp -r /opt/projects/static-website/html/* "$HTML_PATH"

echo "🔐 Ajustando permisos para que NGINX pueda leer los archivos..."
sudo chown -R 101:101 "$HTML_PATH"
sudo chmod -R 755 "$HTML_PATH"

echo "📦 Aplicando los manifiestos de Kubernetes..."
minikube kubectl -- apply -f "$MANIFEST_PATH/persistent-volume.yaml"
minikube kubectl -- apply -f "$MANIFEST_PATH/persistent-volume-claim.yaml"
minikube kubectl -- apply -f "$MANIFEST_PATH/deployment.yaml"
minikube kubectl -- apply -f "$MANIFEST_PATH/service.yaml"

echo "♻ Eliminando pod anterior para forzar el remonte..."
minikube kubectl -- delete pod -l app=sitio-web --ignore-not-found=true

echo "⏳ Esperando a que el nuevo pod esté listo..."
minikube kubectl -- wait --for=condition=ready pod -l app=sitio-web --timeout=60s

echo "✅ Despliegue completo. Verificando estado del servicio..."
minikube service sitio-web-service

