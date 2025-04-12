#!/bin/bash

set -e

VOL_PATH="/mnt/data/sitio-web"
HTML_PATH="$VOL_PATH/html"

echo "📁 Creando carpeta local para archivos del sitio en $HTML_PATH (requiere sudo)..."
sudo mkdir -p "$HTML_PATH"

echo "🧹 Limpiando contenido previo del volumen..."
sudo rm -rf "$HTML_PATH"/*

echo "📄 Copiando archivos del sitio al volumen..."
sudo cp -r html/* "$HTML_PATH"

echo "🔐 Ajustando permisos para que NGINX pueda leer los archivos..."
# NGINX en el contenedor oficial corre como usuario 101
sudo chown -R 101:101 "$HTML_PATH"
sudo chmod -R 755 "$HTML_PATH"

echo "📦 Aplicando los manifiestos de Kubernetes..."

# Usamos minikube ssh para ejecutar kubectl dentro del entorno Minikube
minikube ssh "kubectl apply -f /home/docker/sitio-web/k8sManifests/persistent-volume.yaml"
minikube ssh "kubectl apply -f /home/docker/sitio-web/k8sManifests/persistent-volume-claim.yaml"
minikube ssh "kubectl apply -f /home/docker/sitio-web/k8sManifests/deployment.yaml"
minikube ssh "kubectl apply -f /home/docker/sitio-web/k8sManifests/service.yaml"

echo "♻ Eliminando pod anterior para forzar el remonte..."
minikube ssh "kubectl delete pod -l app=sitio-web --ignore-not-found=true"

echo "⏳ Esperando a que el nuevo pod esté listo..."
minikube ssh "kubectl wait --for=condition=ready pod -l app=sitio-web --timeout=60s"

echo "✅ Despliegue completo. Verificando estado del servicio..."

echo "🌐 Abriendo sitio web..."
minikube service sitio-web-service
