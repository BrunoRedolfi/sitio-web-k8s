# Proyecto: Sitio Web Estático en Kubernetes

Este proyecto despliega un sitio web estático en Minikube utilizando Kubernetes. La página web contiene archivos estáticos como HTML, CSS e imágenes, y se encuentra alojada en un volumen persistente en Minikube.

## Prerequisitos

Asegúrate de tener instalado lo siguiente antes de comenzar:

- **Minikube** - Para ejecutar Kubernetes de manera local.
- **kubectl** - Herramienta de línea de comandos para interactuar con Kubernetes.
- **Git** - Para clonar el repositorio y subir cambios a GitHub.

## Pasos para configurar el entorno

### 1. Clonar los repositorios

Primero, clona ambos repositorios en un directorio común. Vamos a usar `/opt/projects/` como ejemplo:

```bash
sudo mkdir -p /opt/projects
cd /opt/projects
git clone https://github.com/BrunoRedolfi/static-website.git
git clone https://github.com/BrunoRedolfi/sitio-web-k8s.git
```

El contenido del sitio web se encuentra en `/opt/projects/static-website-content/html/`.

### 2. Crear y configurar el clúster en Minikube

Inicia Minikube:

```bash
minikube start
```

### 3. Montar el contenido estático en Minikube

Para que el clúster pueda acceder a los archivos estáticos, es necesario montar la carpeta `html` del proyecto dentro del entorno de Minikube.

Abre una **nueva terminal** y ejecuta el siguiente comando:

```bash
minikube mount /opt/projects/static-website-content/html:/opt/projects/static-website/html
```

⚠️ Este comando debe permanecer ejecutándose mientras Minikube esté en funcionamiento. No cierres la terminal.

### 4. Aplicar los manifiestos de Kubernetes

En una terminal aparte (no la del mount), asegúrate de estar dentro de la carpeta del proyecto y aplica los manifiestos de Kubernetes con los siguientes comandos:

- Crear el volumen persistente:

```bash
kubectl apply -f /opt/projects/sitio-web-k8s/kubernetes-manifests/persistent-volume.yaml
```

- Crear la reclamación de volumen persistente:

```bash
kubectl apply -f /opt/projects/sitio-web-k8s/kubernetes-manifests/persistent-volume-claim.yaml
```

- Desplegar la aplicación web estática:

```bash
kubectl apply -f /opt/projects/sitio-web-k8s/kubernetes-manifests/deployment.yaml
```

- Crear el servicio para exponer la aplicación:

```bash
kubectl apply -f /opt/projects/sitio-web-k8s/kubernetes-manifests/service.yaml
```

### 5. Verificar el despliegue

Puedes verificar que los pods y servicios estén corriendo correctamente con los siguientes comandos:

```bash
kubectl get pods
kubectl get services
```

### 6. Acceder al sitio web

Minikube proporciona una forma fácil de acceder a los servicios a través de un proxy. Ejecuta el siguiente comando para obtener la URL de tu servicio:

```bash
minikube service sitio-web-service --url
```

Esto abrirá un navegador con la URL de tu sitio web desplegado.

### 7. Parar Minikube (opcional)

Cuando termines de trabajar, puedes parar Minikube con el siguiente comando:

```bash
minikube stop
```

Si cerraste la terminal donde corría el mount, deberás volver a montarlo la próxima vez que inicies Minikube.

### 8. Subir cambios al repositorio

Cada vez que realices cambios en el repositorio, no olvides hacer commits y subirlos a GitHub:

```bash
git add .
git commit -m "Descripción de los cambios"
git push origin main
```
