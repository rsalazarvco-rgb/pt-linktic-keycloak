# Entrega de Prueba Técnica

## 1. Resumen

La presente entrega documenta la resolución de una prueba técnica orientada a la migración de un despliegue legado de Keycloak hacia un entorno local basado en Kubernetes. El proceso incluyó análisis del entorno original, identificación de componentes, respaldo de artefactos críticos, restauración de la base de datos y despliegue funcional de la plataforma.

El resultado final fue una solución operativa en Kubernetes local, con restauración exitosa de la base de datos, validación funcional del acceso administrativo y publicación del trabajo en un repositorio GitHub estructurado y sanitizado.

---

## 2. Actividades desarrolladas

Durante la prueba se ejecutaron las siguientes actividades:

1. Acceso y reconocimiento del entorno fuente.
2. Identificación de sistema operativo, versión de Keycloak, Java y base de datos.
3. Validación de la forma de arranque del servicio Keycloak.
4. Respaldo de configuración principal, caché y proxy.
5. Exportación del dump de la base `keycloak`.
6. Construcción de una imagen personalizada de Keycloak.
7. Despliegue de PostgreSQL y Keycloak en Kubernetes local.
8. Restauración de la base de datos dentro del nuevo entorno.
9. Validación funcional del acceso local y externo.
10. Publicación de la solución en GitHub.

---

## 3. Entorno original identificado

El análisis del entorno legado permitió identificar lo siguiente:

- Sistema operativo: Red Hat Enterprise Linux 10.1
- Keycloak: 26.6.0
- Java: 25.0.2
- Base de datos: PostgreSQL
- Publicación original: Caddy como reverse proxy

Este hallazgo fue relevante porque el despliegue correspondía a una versión moderna de Keycloak basada en Quarkus y no a una variante legacy basada en WildFly/JBoss.

---

## 4. Artefactos respaldados

Se respaldaron los siguientes elementos del entorno fuente:

- `keycloak.conf`
- `cache-ispn.xml`
- `Caddyfile`
- definición del servicio `keycloak`
- definición del servicio `caddy`
- dump de la base `keycloak`

Estos elementos permitieron reconstruir la solución sin depender de cambios adicionales sobre la VM original.

---

## 5. Solución implementada

La solución resultante fue desplegada en Kubernetes local con los siguientes componentes:

- Namespace de trabajo
- Secret con configuración sensible
- PersistentVolumeClaim para PostgreSQL
- Deployment de PostgreSQL
- Service de PostgreSQL
- Deployment de Keycloak
- Service de Keycloak

Adicionalmente, se construyó una imagen propia de Keycloak, en lugar de depender exclusivamente de una imagen pública sin personalización.

---

## 6. Validaciones realizadas

### 6.1. Restauración de la base de datos

Se validó la ejecución correcta del dump dentro de PostgreSQL, observando la creación de tablas y la carga de datos durante el arranque del contenedor.

### 6.2. Integridad de la base restaurada

Se comprobó la presencia de 90 tablas en el esquema `public`, confirmando que la restauración fue exitosa.

### 6.3. Estado de la plataforma

Se verificó que los pods de `postgres` y `keycloak` quedaron en estado `1/1 Running`.

### 6.4. Acceso local

Se habilitó acceso local mediante `kubectl port-forward`, confirmando la carga de la pantalla de login en `http://localhost:8080`.

### 6.5. Autenticación administrativa

Se validó el ingreso exitoso al admin console de Keycloak con credenciales restauradas del entorno original.

### 6.6. Acceso externo

Se realizaron pruebas de exposición pública mediante túneles externos, verificando finalmente el acceso correcto una vez corregida la configuración persistida en la base de datos.

---

## 7. Hallazgos principales

Durante el desarrollo se identificaron varios hallazgos relevantes:

- El entorno original correspondía a Keycloak moderno basado en Quarkus.
- PostgreSQL 18 exigió ajustar la ruta de persistencia del volumen.
- Las probes de Kubernetes debieron apuntar al puerto de management/health.
- El atributo `frontendUrl` almacenado en la base explicaba el redireccionamiento al dominio original del entorno fuente.
- La eliminación de `frontendUrl` permitió resolver correctamente el acceso externo, demostrando que el problema no estaba en la infraestructura sino en una configuración heredada del realm.

---

## 8. Resultado obtenido

La actividad quedó resuelta satisfactoriamente en sus objetivos principales. Se logró:

- analizar el despliegue legado;
- respaldar los artefactos críticos;
- restaurar la base de datos;
- desplegar Keycloak y PostgreSQL en Kubernetes local;
- validar el acceso funcional local a la plataforma;
- validar también el acceso externo una vez corregida la configuración heredada;
- publicar la solución en GitHub.

---

## 9. Dificultades encontradas y resolución

Las principales dificultades técnicas estuvieron asociadas a:

- diferencias entre el entorno esperado y el entorno real;
- necesidad de adaptar la persistencia a PostgreSQL 18;
- ajuste de probes para estabilizar Keycloak;
- presencia de configuración heredada en la base restaurada.

La dificultad más relevante fue el redireccionamiento persistente al dominio original. Este comportamiento fue rastreado hasta el atributo `frontendUrl` en la tabla `realm_attribute`. Una vez eliminado dicho registro, el acceso local y externo se estabilizaron correctamente.

---

## 10. Repositorio de entrega

La solución fue publicada en el siguiente repositorio:
```text
https://github.com/rsalazarvco-rgb/pt-linktic-keycloak
````
---

## 11. Conclusión

La prueba técnica fue resuelta con éxito en su componente principal de análisis, migración y reconstrucción. La plataforma quedó operativa en Kubernetes local, con persistencia funcional, base restaurada y acceso validado al admin console tanto en entorno local como en validación externa.

El principal hallazgo técnico fue la identificación del atributo `frontendUrl` persistido en la base restaurada, cuya eliminación permitió resolver el comportamiento heredado del entorno original y cerrar satisfactoriamente la validación final de la solución.

