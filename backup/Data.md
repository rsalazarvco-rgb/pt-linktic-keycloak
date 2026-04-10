# Backups y proceso de restauración

## 1. Propósito

Este documento describe los artefactos de respaldo utilizados durante la migración de la plataforma, su finalidad dentro del proceso de reconstrucción y las consideraciones aplicadas para su uso en el entorno local de Kubernetes.

El objetivo de estos respaldos fue permitir la reconstrucción funcional de la solución sin depender operativamente de la máquina virtual original, preservando tanto la configuración esencial como la información persistida en la base de datos.

---

## 2. Alcance de los respaldos

Durante la fase de extracción del entorno origen se identificó que no era suficiente respaldar únicamente la base de datos. Para reconstruir correctamente la solución también fue necesario conservar archivos de configuración y evidencia del comportamiento original del despliegue.

Los respaldos contemplados para la migración fueron:

- respaldo de la base de datos `keycloak`
- respaldo de configuración principal de Keycloak
- respaldo de configuración de caché
- respaldo de configuración del proxy inverso
- respaldo de definiciones de servicios del entorno original

---

## 3. Artefactos de respaldo considerados

### 3.1. Dump de base de datos

**Archivo original usado durante la migración:**  
`keycloak.sql`

### Finalidad
Este archivo contiene el esquema y los datos persistidos de la base `keycloak`, incluyendo tablas, índices, restricciones y registros funcionales necesarios para que la plataforma conserve usuarios, clientes, configuraciones y demás elementos del entorno restaurado.

### Uso en la reconstrucción
El dump fue utilizado durante la inicialización del contenedor de PostgreSQL, permitiendo reconstruir la base funcional dentro del entorno local.

### Consideración de seguridad
El dump real **no debe publicarse** en el repositorio público, ya que puede contener datos sensibles, configuraciones internas y metadatos del entorno original.

---

### 3.2. Archivo principal de configuración de Keycloak

**Archivo respaldado:**  
`keycloak.conf`

### Finalidad
Este archivo permitió identificar y reutilizar parámetros esenciales del despliegue original, por ejemplo:

- tipo de base de datos
- usuario de conexión
- URL JDBC
- habilitación de health y metrics
- hostname configurado en el entorno original

### Uso en la reconstrucción
Aunque no se montó de forma idéntica dentro del nuevo despliegue, fue utilizado como referencia para traducir la configuración original hacia variables de entorno, parámetros de arranque y manifiestos de Kubernetes.

### Consideración de seguridad
Si el archivo contiene credenciales o valores sensibles, no debe subirse sin sanitización.

---

### 3.3. Archivo de caché de Keycloak

**Archivo respaldado:**  
`cache-ispn.xml`

### Finalidad
Este archivo define la configuración de Infinispan utilizada por Keycloak para la operación de sesiones, cachés internas y comportamiento distribuido.

### Uso en la reconstrucción
Fue incluido en la imagen personalizada de Keycloak para conservar coherencia técnica con el entorno original y reducir diferencias innecesarias en el comportamiento del runtime.

---

### 3.4. Configuración del proxy inverso

**Archivo respaldado:**  
`Caddyfile`

### Finalidad
Este archivo permitió entender cómo era publicada la aplicación en el entorno original, confirmando que Keycloak no terminaba TLS directamente y que la exposición externa dependía de un reverse proxy.

### Uso en la reconstrucción
Se utilizó como artefacto de referencia arquitectónica, no como componente obligatorio del despliegue inicial en Kubernetes local.

---

### 3.5. Definiciones de servicios del entorno original

**Archivos respaldados:**
- `keycloak.service.txt`
- `caddy.service.txt`

### Finalidad
Estos archivos permitieron evidenciar:

- cómo arrancaba Keycloak originalmente
- qué argumentos se utilizaban
- cómo se comportaba el servicio en la VM
- cómo se integraba el proxy con la aplicación

### Uso en la reconstrucción
Sirvieron como insumo para construir una imagen de Keycloak y definir una estrategia de despliegue equivalente en Kubernetes.

---

## 4. Estructura recomendada para los respaldos

En el entorno de trabajo local, los respaldos se organizaron de la siguiente manera:

Nota: El acceso a las copias de seguridad requiere clave de autenticación. Comuníquese con el administrador, para mayor información o para su respectiva autorización de acceso.

```text
backup/
├── postgres/
│   └── keycloak.sql
├── keycloak/
│   ├── keycloak.conf
│   ├── cache-ispn.xml
│   └── keycloak.service.txt
└── caddy/
    ├── Caddyfile
    └── caddy.service.txt
