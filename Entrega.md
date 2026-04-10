# Entrega de Prueba Técnica - Migración de Keycloak a Kubernetes Local

## 1. Resumen ejecutivo

Esta entrega documenta el proceso técnico seguido para analizar un despliegue legado de Keycloak ejecutándose sobre una máquina virtual Linux, respaldar sus artefactos críticos, contenerizar la solución y reconstruirla exitosamente en un entorno local basado en Kubernetes.

El ejercicio incluyó identificación de versión de Keycloak, Java y PostgreSQL, extracción de configuración, respaldo de la base de datos, construcción de una imagen propia de Keycloak, despliegue en Kubernetes local y validación funcional del acceso administrativo. Adicionalmente, se evaluó la exposición pública mediante túneles seguros, identificando una limitación asociada al flujo web del admin console en navegadores externos.

---

## 2. Alcance de la prueba

De acuerdo con la prueba técnica, los objetivos principales consistían en:

1. Analizar el despliegue actual en la VM.
2. Identificar la versión de Java, Keycloak y la base de datos utilizada.
3. Localizar y respaldar artefactos críticos.
4. Contenerizar la aplicación y la base de datos siguiendo buenas prácticas.
5. Desplegar la solución en entorno local.
6. Exponer el servicio para revisión externa.
7. Entregar la solución en un repositorio público con instrucciones de reproducción. :contentReference[oaicite:0]{index=0}

---

## 3. Entorno origen identificado

A partir del acceso SSH suministrado y del análisis del entorno original, se identificó lo siguiente:

### 3.1 Sistema operativo
- Red Hat Enterprise Linux 10.1

### 3.2 Keycloak
- Versión: **Keycloak 26.6.0**
- Tipo de despliegue: **Keycloak moderno basado en Quarkus**
- Ejecución mediante servicio `systemd`

### 3.3 Java
- Versión: **Java 25.0.2**

### 3.4 Base de datos
- Motor: **PostgreSQL**
- Base funcional: **keycloak**
- El dump fue generado con PostgreSQL 18.3

### 3.5 Publicación original
- Reverse proxy: **Caddy**
- Dominio identificado en el entorno original: `54-204-127-32.sslip.io`

### 3.6 Configuración principal encontrada
- Archivo principal de Keycloak: `keycloak.conf`
- Archivo de cache: `cache-ispn.xml`
- Archivo de proxy: `Caddyfile`

---

## 4. Artefactos críticos respaldados

Durante la fase de extracción se respaldaron los siguientes elementos:

- `keycloak.conf`
- `cache-ispn.xml`
- `Caddyfile`
- definición del servicio `keycloak`
- definición del servicio `caddy`
- dump de la base de datos `keycloak`

Estos artefactos permitieron reconstruir la solución sin seguir interviniendo la VM original.

---

## 5. Análisis técnico del entorno legado

El entorno original no correspondía a una instalación legacy basada en WildFly/JBoss, sino a una versión moderna de Keycloak basada en Quarkus. Esto fue importante porque modificó completamente la estrategia de migración: en lugar de rescatar configuraciones tipo `standalone.xml`, el proceso se enfocó en la configuración nativa de Keycloak moderno, sus parámetros de arranque, la integración con PostgreSQL y la lógica de publicación detrás de proxy. Esta identificación temprana permitió reducir complejidad, ajustar mejor la contenerización y evitar una estrategia equivocada de migración.

---

## 6. Estrategia de migración adoptada

Se adoptó la siguiente estrategia:

1. **No modificar el entorno original más de lo necesario.**
2. Realizar solo operaciones de inspección, copia y respaldo sobre la VM.
3. Extraer la base de datos y archivos críticos.
4. Construir una **imagen propia de Keycloak**.
5. Desplegar la solución en **Kubernetes local** para obtener mayor puntaje técnico.
6. Validar acceso local antes de intentar exposición pública.
7. Documentar las observaciones finales sin seguir alterando una solución ya estable.

---

## 7. Solución implementada

### 7.1 Plataforma de ejecución
- Docker Desktop
- kind
- kubectl
- Kubernetes local

### 7.2 Componentes desplegados
- **Deployment de PostgreSQL**
- **Deployment de Keycloak**
- **Service de PostgreSQL**
- **Service de Keycloak**
- **PersistentVolumeClaim**
- **Secret**
- **Namespace**
- **ConfigMap** para inicialización de base

### 7.3 Imagen personalizada
Se construyó una imagen propia de Keycloak 26.6.0 a partir de un `Dockerfile`, en lugar de usar directamente una imagen sin personalización. Esto permitió mantener coherencia con el requerimiento de redactar una solución propia y reproducible. :contentReference[oaicite:1]{index=1}

---

## 8. Estructura del repositorio

La solución se organizó para publicación en GitHub con estructura sanitizada, excluyendo secretos y datos sensibles.

```text
.
├── Dockerfile
├── README.md
├── Entrega.md
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
