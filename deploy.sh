#!/bin/bash

set -e

VOL_PATH="/mnt/data/static-website"
HTML_PATH="$VOL_PATH/html"
MANIFEST_PATH="./k8sManifests"

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


echo "🧽 Verificando si el PVC ya existe para recrearlo..."
if minikube kubectl -- get pvc web-content-pvc >/dev/null 2>&1; then
  echo "📛 Forzando eliminación de finalizers del PVC (modo desarrollo)..."
  minikube kubectl -- patch pvc web-content-pvc -p '{"metadata":{"finalizers":null}}' --type=merge || true
  echo "🗑 Borrando PersistentVolumeClaim existente..."
  minikube kubectl -- delete pvc web-content-pvc --grace-period=0 --force || true
fi
sleep 2

echo "🧽 Verificando si el PV ya existe para recrearlo..."
if minikube kubectl -- get pv web-content-pv >/dev/null 2>&1; then
  echo "🗑 Borrando PersistentVolume existente..."
  minikube kubectl -- delete pv web-content-pv
fi
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

