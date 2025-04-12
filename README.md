Proyecto: Sitio Web Estático en Kubernetes

Este proyecto despliega un sitio web estático en Minikube utilizando Kubernetes. La página web contiene archivos estáticos como HTML, CSS e imágenes, y se encuentra alojada en un volumen persistente en Minikube.
Prerequisitos

Asegúrate de tener instalado lo siguiente antes de comenzar:

    Minikube - Para ejecutar Kubernetes de manera local.

    kubectl - Herramienta de línea de comandos para interactuar con Kubernetes.

    Git - Para clonar el repositorio y subir cambios a GitHub.

Pasos para configurar el entorno
1. Clonar el repositorio

Primero, clona este repositorio en tu máquina local:

  git clone https://github.com/BrunoRedolfi/sitio-web-k8s.git
  cd sitio-web-k8s

2. Crear y configurar el clúster en Minikube

Inicia Minikube:
  
  minikube start

3. Aplicar los manifiestos de Kubernetes

Asegúrate de estar dentro de la carpeta del proyecto y aplica los manifiestos de Kubernetes con los siguientes comandos:

Crear el volumen persistente:

  kubectl apply -f kubernetes-manifests/persistent-volume.yaml

Crear la reclamación de volumen persistente:

  kubectl apply -f kubernetes-manifests/persistent-volume-claim.yaml

Desplegar la aplicación web estática:

  kubectl apply -f kubernetes-manifests/deployment.yaml

Crear el servicio para exponer la aplicación:

  kubectl apply -f kubernetes-manifests/service.yaml

4. Verificar el despliegue

Puedes verificar que los pods y servicios estén corriendo correctamente con los siguientes comandos:
  kubectl get pods
  kubectl get services

5. Acceder al sitio web

Minikube proporciona una forma fácil de acceder a los servicios a través de un proxy. Ejecuta el siguiente comando para obtener la URL de tu servicio:

  minikube service sitio-web-service --url

Esto abrirá un navegador con la URL de tu sitio web desplegado.

6. Parar Minikube (opcional)

Cuando termines de trabajar, puedes parar Minikube con el siguiente comando:

  minikube stop

7. Subir cambios al repositorio

Cada vez que realices cambios en el repositorio, no olvides hacer commits y subirlos a GitHub:
  git add .
  git commit -m "Descripción de los cambios"
  git push origin main


