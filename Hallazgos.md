# Hallazgos técnicos

## 1. Introducción

Este documento consolida los principales hallazgos identificados durante la ejecución de la prueba técnica, incluyendo diferencias entre el entorno esperado y el entorno real, ajustes adicionales necesarios para resolver la migración y decisiones técnicas aplicadas durante la validación.

---

## 2. Hallazgos del entorno original

### 2.1. Keycloak no correspondía a una versión legacy

La instalación fuente no estaba basada en WildFly/JBoss, sino en una versión moderna de Keycloak ejecutándose sobre Quarkus. Este hallazgo fue importante porque obligó a replantear la estrategia de migración y a descartar un enfoque orientado a rescatar configuraciones tipo `standalone.xml`.

### 2.2. Versiones reales del entorno

La validación directa del entorno original permitió identificar como versiones efectivas:

- Keycloak 26.6.0
- Java 25.0.2
- PostgreSQL como motor de base de datos

La identificación precisa de estas versiones fue necesaria para construir una solución consistente con el runtime original.

### 2.3. Publicación original mediante reverse proxy

Se comprobó que la publicación del entorno original no se hacía directamente desde Keycloak, sino a través de Caddy como reverse proxy. Esto evidenció que la exposición externa dependía de una capa adicional de publicación y no del servicio de Keycloak de forma aislada.

---

## 3. Diferencias identificadas entre el entorno esperado y el entorno real

### 3.1. Diferencia entre la información inicial y la configuración efectiva

Durante la revisión técnica se observó que no toda la información inicial podía asumirse como verdad absoluta. Fue necesario validar directamente en la máquina virtual la configuración operativa real del entorno, incluyendo servicios, puertos, procesos, versiones y parámetros de arranque.

### 3.2. Diferencia entre el puerto funcional de la aplicación y el puerto de health/management

Se comprobó que Keycloak exponía la aplicación en el puerto `8080`, mientras la interfaz de health/management operaba en `9000`. Esta diferencia fue importante porque inicialmente las probes apuntaban al puerto funcional y Kubernetes no marcaba el pod como listo, aunque el proceso ya estuviera iniciado.

### 3.3. Diferencia entre acceso local y comportamiento heredado del entorno restaurado

Aunque el despliegue local ya no incluía un `hostname` externo explícito en Kubernetes, la aplicación seguía heredando parte del comportamiento del entorno original. Esto evidenció que una parte del comportamiento de Keycloak no dependía solamente de los manifiestos del clúster, sino también de la configuración persistida dentro de la base de datos restaurada.

---

## 4. Procedimientos adicionales necesarios para resolver la actividad

### 4.1. Respaldo ampliado de artefactos

No fue suficiente con respaldar la base de datos. También fue necesario extraer:

- `keycloak.conf`
- `cache-ispn.xml`
- `Caddyfile`
- definiciones de servicios
- evidencia del comportamiento del entorno original

Esto permitió reconstruir no solo los datos, sino también el contexto operativo de la solución fuente.

### 4.2. Construcción de una imagen propia de Keycloak

Se generó una imagen personalizada de Keycloak, en lugar de utilizar una imagen pública sin adaptación. Esta decisión permitió alinear el despliegue local con el comportamiento observado en el entorno original y cumplir mejor el criterio de una solución reproducible.

### 4.3. Ajuste de la persistencia para PostgreSQL 18

Durante la restauración fue necesario adaptar la ruta de persistencia de PostgreSQL 18, ya que la convención esperada por esa versión difiere de la usada en versiones anteriores. Sin este ajuste, el contenedor no completaba correctamente su inicialización.

### 4.4. Reinicialización controlada del PVC

En pruebas intermedias fue necesario eliminar y recrear el volumen persistente de PostgreSQL para forzar una restauración limpia del dump y evitar que el servicio reutilizara un estado parcial ya existente.

### 4.5. Ajuste de las probes de Keycloak

Se ajustaron las probes de `readiness` y `liveness` para apuntar al puerto `9000`, correspondiente a la interfaz de health/management. Este cambio permitió estabilizar correctamente el estado del pod dentro de Kubernetes.

---

## 5. Hallazgo crítico que permitió resolver el acceso externo

### 5.1. Identificación del atributo `frontendUrl` en la base restaurada

El hallazgo más importante de la fase final fue la identificación del atributo `frontendUrl` persistido en la tabla `realm_attribute`. Este valor conservaba el dominio del entorno original y provocaba redireccionamientos no deseados durante la validación local y externa.

En otras palabras, el problema no estaba en:

- Kubernetes,
- PostgreSQL,
- el reverse proxy temporal,
- ni en los túneles externos,

sino en una configuración heredada desde la base restaurada.

### 5.2. Impacto del atributo `frontendUrl`

Mientras dicho atributo permaneció con un valor heredado del entorno fuente, Keycloak seguía resolviendo parte de sus redirecciones contra el dominio antiguo. Esto explicaba por qué el acceso externo no se comportaba de manera consistente, a pesar de que:

- la aplicación ya estaba desplegada;
- la base ya estaba restaurada;
- y la conectividad externa ya alcanzaba el servicio.

### 5.3. Resolución aplicada

La resolución consistió en eliminar el registro `frontendUrl` de la base de datos restaurada. Una vez eliminado, Keycloak dejó de forzar la referencia al dominio heredado y pudo resolver correctamente el acceso desde el entorno actual.

Este ajuste permitió validar con éxito el acceso externo, demostrando que la causa real del problema no estaba en la infraestructura sino en una configuración persistida del realm.

---

## 6. Problemas inicialmente observados y estado final

### 6.1. Redireccionamiento al dominio original

Inicialmente, al ingresar a la aplicación desde el entorno local, Keycloak redirigía al dominio del despliegue fuente. Este comportamiento quedó explicado por la presencia de `frontendUrl` en la base restaurada.

**Estado final:** resuelto.

### 6.2. Inestabilidad inicial del pod de Keycloak

Durante el despliegue, Keycloak alcanzó temporalmente estados `0/1 Running`, aunque el proceso de la aplicación ya se encontraba iniciado.

**Estado final:** resuelto mediante ajuste de probes.

### 6.3. Acceso administrativo externo

En una fase intermedia, el acceso administrativo externo mediante túneles temporales alcanzaba la aplicación, pero no se comportaba correctamente.

**Estado final:** resuelto al eliminar el atributo `frontendUrl` persistido en la base de datos.

---

## 7. Estado final alcanzado

Con los ajustes realizados, el estado final de la solución fue satisfactorio y completo en los aspectos principales de la prueba:

- análisis correcto del entorno legado;
- respaldo de artefactos críticos;
- restauración íntegra de la base de datos;
- construcción de una imagen propia de Keycloak;
- despliegue exitoso de PostgreSQL y Keycloak en Kubernetes local;
- acceso funcional local al admin console;
- acceso externo validado una vez resuelta la configuración heredada en base de datos;
- publicación de la solución en GitHub.

---

## 8. Conclusión

El principal aprendizaje técnico de la actividad fue que una migración exitosa de Keycloak no depende únicamente del despliegue de contenedores, la restauración de la base o la conectividad de red, sino también de la coherencia entre la configuración persistida del realm y el nuevo entorno donde la plataforma es reconstruida.

El hallazgo del atributo `frontendUrl` fue decisivo para cerrar correctamente la validación de la solución. Gracias a ello, la plataforma no solo quedó operativa en entorno local, sino también funcional en el acceso externo validado durante la prueba.
