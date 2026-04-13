# Pruebas y resultados obtenidos

## 1. Propósito

Este documento resume las principales pruebas ejecutadas durante la migración de Keycloak hacia un entorno local basado en Kubernetes, así como los resultados obtenidos en cada una de ellas. Su objetivo es evidenciar de manera concreta la validación técnica de la solución implementada.

---

## 2. Prueba de acceso y análisis del entorno original

Se validó el acceso exitoso al servidor fuente y se realizó el reconocimiento técnico del entorno original. A partir de este análisis se identificó:

- sistema operativo del entorno fuente;
- versión real de Keycloak;
- versión de Java;
- motor de base de datos utilizado;
- existencia de un reverse proxy para publicación externa.

### Resultado obtenido

El entorno original fue identificado correctamente y se confirmó que la plataforma correspondía a un despliegue moderno de Keycloak basado en Quarkus, respaldado por PostgreSQL y publicado mediante Caddy.

---

## 3. Prueba de extracción y respaldo de artefactos críticos

Se ejecutó la extracción de los artefactos necesarios para reconstruir la solución fuera de la máquina virtual original. Los elementos respaldados incluyeron:

- `keycloak.conf`
- `cache-ispn.xml`
- `Caddyfile`
- definiciones de servicios
- dump de la base `keycloak`

### Resultado obtenido

Los artefactos críticos fueron respaldados correctamente, permitiendo reconstruir el entorno sin continuar interviniendo la VM de origen.

---

## 4. Prueba de exportación y restauración de la base de datos

Se generó un dump de la base `keycloak` desde el entorno original y posteriormente se restauró en una instancia de PostgreSQL desplegada en Kubernetes local.

La restauración fue validada mediante:

- logs del contenedor de PostgreSQL;
- ejecución del script SQL de inicialización;
- consulta directa al número de tablas restauradas.

### Resultado obtenido

La restauración fue exitosa. La validación confirmó la existencia de **90 tablas** en el esquema `public`, demostrando que la base fue reconstruida correctamente con su estructura y datos funcionales.

---

## 5. Prueba de construcción de imagen personalizada

Se construyó una imagen propia de Keycloak a partir de un `Dockerfile`, incorporando los elementos necesarios para conservar coherencia con el entorno original.

### Resultado obtenido

La imagen fue construida satisfactoriamente y cargada al clúster local, cumpliendo con el criterio de una solución contenerizada y reproducible.

---

## 6. Prueba de despliegue en Kubernetes local

Se desplegaron en el clúster local los recursos necesarios para soportar la solución:

- namespace;
- secret;
- persistent volume claim;
- deployment de PostgreSQL;
- deployment de Keycloak;
- services asociados.

### Resultado obtenido

La infraestructura local quedó desplegada correctamente y los recursos fueron administrables desde Kubernetes mediante `kubectl`.

---

## 7. Prueba de estabilidad de PostgreSQL

Se validó el estado del pod de PostgreSQL, el comportamiento del volumen persistente y la ejecución del proceso de inicialización de la base de datos.

### Resultado obtenido

PostgreSQL quedó estable en estado `1/1 Running`, con logs consistentes y sin errores de inicialización posteriores a la restauración del dump.

---

## 8. Prueba de estabilidad de Keycloak

Se validó el arranque de Keycloak y su comportamiento dentro del clúster. Durante esta fase fue necesario ajustar las probes al puerto de health/management para que Kubernetes reconociera correctamente la disponibilidad del servicio.

### Resultado obtenido

Keycloak quedó estable en estado `1/1 Running`, con arranque exitoso, bootstrap completado y escucha activa en el puerto `8080`.

---

## 9. Prueba de acceso local a la aplicación

Se habilitó el acceso local mediante `kubectl port-forward` y se realizó la validación funcional desde navegador en:

`http://localhost:8080`

### Resultado obtenido

La pantalla de login de Keycloak cargó correctamente y la aplicación quedó accesible desde el entorno local.

---

## 10. Prueba de autenticación funcional

Se realizó el ingreso al admin console utilizando las credenciales administrativas restauradas desde el entorno original.

### Resultado obtenido

El acceso al panel de administración fue exitoso, confirmando que la plataforma se encontraba operativa y que la base de datos restaurada conservó la información funcional necesaria para autenticación y administración.

---

## 11. Prueba de diagnóstico sobre redireccionamiento heredado

Durante la validación se detectó un comportamiento de redireccionamiento al dominio original del entorno fuente. Se realizaron consultas sobre la base restaurada hasta identificar el atributo `frontendUrl` en la tabla `realm_attribute`.

### Resultado obtenido

Se confirmó que el problema no provenía del deployment de Kubernetes ni del servicio de red, sino de una configuración persistida en la base de datos restaurada.

---

## 12. Prueba de corrección del `frontendUrl`

Se eliminó el atributo `frontendUrl` heredado del entorno original y se reinició Keycloak para validar el comportamiento resultante.

### Resultado obtenido

La eliminación de `frontendUrl` resolvió el comportamiento heredado y permitió estabilizar correctamente la resolución de URLs del entorno actual.

---

## 13. Prueba de acceso externo

Se realizaron pruebas de publicación externa mediante túneles temporales hacia la solución desplegada localmente. Inicialmente, la aplicación era alcanzable pero persistían comportamientos anómalos debido a la configuración heredada del realm.

Una vez eliminado `frontendUrl`, se repitió la validación de acceso externo.

### Resultado obtenido

El acceso externo quedó funcional. La conectividad hacia la aplicación y la validación del acceso se completaron exitosamente una vez corregida la configuración persistida en la base de datos.

---

## 14. Prueba de publicación en GitHub

Se estructuró y publicó un repositorio público con la solución sanitizada, excluyendo secretos, credenciales reales y dumps sensibles.

### Resultado obtenido

La solución quedó disponible en GitHub con:

- manifiestos de Kubernetes;
- `Dockerfile`;
- documentación técnica;
- hallazgos;
- comandos ejecutados;
- consideraciones de seguridad;
- y evidencias de soporte.

---

## 15. Resultado consolidado de la actividad

A partir de las pruebas ejecutadas, se concluye que la actividad fue resuelta satisfactoriamente en sus objetivos principales:

- se analizó correctamente el entorno legado;
- se respaldaron los artefactos críticos;
- se exportó y restauró la base de datos;
- se construyó una imagen propia de Keycloak;
- se desplegó la solución en Kubernetes local;
- se validó el acceso local al admin console;
- se corrigió la configuración heredada que afectaba la resolución de URLs;
- se validó el acceso externo;
- y se publicó la solución en GitHub.

---

## 16. Conclusión

Las pruebas ejecutadas permiten afirmar que la migración y reconstrucción de la plataforma fueron exitosas. La solución quedó operativa, estable y validada funcionalmente tanto en entorno local como en acceso externo, cumpliendo con el núcleo técnico de la prueba y dejando documentados los principales hallazgos y decisiones adoptadas durante su resolución.
