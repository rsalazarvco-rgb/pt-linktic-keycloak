
# Pruebas y resultados obtenidos

Este documento resume las pruebas ejecutadas para validar la migración de Keycloak desde un entorno legado hacia un despliegue local en Kubernetes, así como los resultados obtenidos en cada fase.

---

## 1. Prueba de acceso y análisis del entorno original

Se validó el acceso exitoso al servidor fuente mediante SSH y se realizó el reconocimiento técnico del entorno. Como resultado, se identificó que la plataforma original estaba compuesta por:

- Keycloak 26.6.0
- Java 25.0.2
- PostgreSQL como motor de base de datos
- publicación mediante Caddy como reverse proxy

**Resultado:**  
Se obtuvo visibilidad completa del entorno original, permitiendo identificar versiones, servicios, puertos y archivos de configuración clave.

---

## 2. Prueba de extracción y respaldo de artefactos críticos

Se extrajeron y respaldaron los archivos necesarios para reconstruir la solución fuera de la VM original. Entre ellos:

- `keycloak.conf`
- `cache-ispn.xml`
- `Caddyfile`
- definición de servicios
- dump de la base `keycloak`

**Resultado:**  
Se consolidaron los artefactos mínimos necesarios para realizar una migración controlada sin seguir interviniendo el entorno fuente.

---

## 3. Prueba de exportación y restauración de base de datos

Se generó un dump de la base de datos `keycloak` y posteriormente se restauró en PostgreSQL desplegado en Kubernetes local. La restauración se verificó revisando los logs del contenedor y consultando directamente la cantidad de tablas restauradas.

**Resultado:**  
La restauración fue exitosa. La validación de base confirmó la presencia de **90 tablas** en el esquema `public`, evidenciando que el esquema y los datos funcionales fueron recuperados correctamente.

---

## 4. Prueba de construcción de imagen personalizada

Se construyó una imagen propia de Keycloak a partir de un `Dockerfile`, incorporando los ajustes necesarios para conservar coherencia con el entorno original.

**Resultado:**  
La imagen fue generada satisfactoriamente y cargada al clúster local de Kubernetes, cumpliendo con el requerimiento de no depender únicamente de una imagen pública sin personalización.

---

## 5. Prueba de despliegue en Kubernetes local

Se desplegaron en Kubernetes los recursos necesarios para la solución:

- Namespace
- Secret
- PersistentVolumeClaim
- Deployment de PostgreSQL
- Deployment de Keycloak
- Services asociados

**Resultado:**  
La infraestructura local quedó desplegada correctamente y los recursos pudieron ser gestionados desde `kubectl`.

---

## 6. Prueba de estabilidad de PostgreSQL

Se validó el estado del pod de PostgreSQL, la ejecución del script de inicialización y el comportamiento posterior del servicio.

**Resultado:**  
PostgreSQL quedó en estado `1/1 Running`, con logs consistentes y sin errores de inicialización posteriores a la restauración.

---

## 7. Prueba de estabilidad de Keycloak

Se validó el arranque de Keycloak, ajustando los parámetros necesarios para que el servicio fuera reconocido correctamente por Kubernetes.

**Resultado:**  
Keycloak quedó en estado `1/1 Running`, con bootstrap exitoso, operación estable y escucha activa en el puerto `8080`.

---

## 8. Prueba de acceso local a la aplicación

Se habilitó el acceso local mediante `kubectl port-forward` y se verificó la carga de la pantalla de login en navegador.

**Resultado:**  
La consola de acceso de Keycloak fue cargada correctamente en `http://localhost:8080`.

---

## 9. Prueba de autenticación funcional

Se realizó el ingreso al admin console usando las credenciales administrativas restauradas desde el entorno original.

**Resultado:**  
El acceso al panel de administración fue exitoso, confirmando que la restauración de la base y la operación de la aplicación eran funcionales.

---

## 10. Prueba de comportamiento frente al hostname heredado

Durante la validación local se observó un redireccionamiento inesperado al dominio original del entorno fuente. Se realizó análisis sobre la base restaurada y se identificó la causa en el atributo `frontendUrl`.

**Resultado:**  
Se confirmó que el comportamiento no provenía del `Deployment` de Kubernetes, sino de una configuración persistida en la base de datos restaurada.

---

## 11. Prueba de exposición pública

Se probaron mecanismos de publicación externa mediante túneles seguros. En ambos casos la aplicación pudo ser alcanzada desde una URL pública.

**Resultado:**  
La conectividad hasta la aplicación fue exitosa; sin embargo, el acceso al admin console desde la URL externa presentó una limitación asociada al flujo web de validación por iframe/cookies del navegador.

---

## 12. Publicación de resultados en GitHub

Se creó un repositorio público con la solución sanitizada, excluyendo secretos, credenciales reales y dumps sensibles.

**Resultado:**  
La solución quedó publicada en GitHub con estructura organizada, documentación y archivos necesarios para revisión.

---

## 13. Resultado consolidado de la actividad

A partir de las pruebas ejecutadas, se concluye que la actividad fue resuelta satisfactoriamente en sus objetivos principales:

- se analizó correctamente el entorno legado;
- se respaldaron los artefactos críticos;
- se restauró la base de datos;
- se construyó una imagen propia de Keycloak;
- se desplegó la solución en Kubernetes local;
- se validó el acceso funcional local al admin console;
- y se documentó la entrega en un repositorio público.

La principal limitación observada quedó restringida al acceso administrativo externo mediante URL pública temporal, sin afectar el funcionamiento local de la solución ni el resultado general de la migración.

---

## 14. Conclusión

Las pruebas ejecutadas permiten afirmar que la migración y reconstrucción de la plataforma fueron exitosas en entorno local. La solución quedó operativa, estable y validada funcionalmente, cumpliendo con el núcleo técnico de la prueba y dejando documentadas las observaciones necesarias sobre la publicación externa.
