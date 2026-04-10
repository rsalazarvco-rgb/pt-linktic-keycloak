# pt-linktic-keycloak
# Migración de Keycloak a Kubernetes local

## 1. Descripción general

Este repositorio contiene la solución desarrollada para una prueba técnica orientada al análisis de un despliegue legado de Keycloak, la extracción de su configuración y datos críticos, y su reconstrucción en un entorno local basado en contenedores y Kubernetes.

La solución parte de una instalación existente de Keycloak ejecutándose sobre una máquina virtual Linux, respaldada por PostgreSQL y publicada originalmente mediante un reverse proxy. A partir de ese entorno, se realizó un proceso controlado de reconocimiento, respaldo, contenerización y despliegue local, con el objetivo de obtener una solución funcional, portable y reproducible.

## 2. Objetivo de la solución

El propósito de esta implementación fue:

- Analizar el despliegue existente de Keycloak en una VM.
- Identificar versión de Keycloak, Java y base de datos.
- Respaldar artefactos críticos de configuración.
- Extraer y restaurar la base de datos de la plataforma.
- Construir una imagen propia de Keycloak.
- Desplegar la solución en un entorno local de Kubernetes.
- Validar el acceso funcional a la consola de Keycloak.

## 3. Arquitectura resultante

La arquitectura final implementada en entorno local quedó compuesta por los siguientes elementos:

- **Kubernetes local** ejecutado sobre `kind`.
- **PostgreSQL** desplegado como `Deployment` con almacenamiento persistente mediante `PersistentVolumeClaim`.
- **Keycloak 26.6.0** desplegado como `Deployment`.
- **Secret de Kubernetes** para variables sensibles de conexión.
- **Services tipo ClusterIP** para comunicación interna entre Keycloak y PostgreSQL.
- **Port-forward** para acceso local a la consola web.

## 4. Tecnologías utilizadas

- Docker Desktop
- kind
- kubectl
- PostgreSQL 18
- Keycloak 26.6.0
- PowerShell
- Kubernetes YAML manifests

## 5. Estructura del repositorio

```text
.
├── Dockerfile
├── README.md
├── .gitignore
├── k8s/
│   ├── namespace.yaml
│   ├── secret-example.yaml
│   ├── postgres-pvc.yaml
│   ├── postgres-service.yaml
│   ├── postgres-deployment.yaml
│   ├── keycloak-service.yaml
│   └── keycloak-deployment.yaml
├── docs/
│   └── screenshots/
└── backup/
    └── README.md
