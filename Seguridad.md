# Seguridad y consideraciones técnicas

## 1. Propósito

Este documento resume los principales aspectos de seguridad considerados durante la ejecución de la prueba técnica, así como las decisiones adoptadas para proteger información sensible, reducir riesgos durante la migración y publicar la solución de forma responsable en GitHub.

---

## 2. Principios aplicados

Durante la ejecución del ejercicio se procuró trabajar bajo los siguientes principios:

- minimizar cambios sobre el entorno original;
- tratar la máquina virtual fuente como sistema de referencia y no como entorno de experimentación;
- respaldar artefactos críticos antes de cualquier modificación;
- evitar exposición innecesaria de secretos;
- publicar únicamente una versión sanitizada del trabajo en GitHub;
- documentar hallazgos y decisiones sin comprometer información sensible.

---

## 3. Seguridad del entorno original

### 3.1. Acceso controlado al servidor fuente

El acceso al entorno original se realizó mediante SSH, utilizando los datos suministrados para la prueba. Las operaciones realizadas sobre la VM se limitaron inicialmente a reconocimiento, lectura y respaldo de información.

### 3.2. Estrategia de intervención mínima

No se realizaron cambios directos sobre la VM original mientras no se tuvo claridad sobre:

- versión real de Keycloak;
- configuración activa;
- base de datos utilizada;
- modo de arranque del servicio;
- publicación mediante proxy.

Esta decisión redujo el riesgo de afectar una plataforma aún no comprendida completamente.

### 3.3. Respaldo previo de artefactos críticos

Antes de trasladar la solución al entorno local, se respaldaron:

- configuración principal de Keycloak;
- configuración de caché;
- configuración del proxy;
- definiciones de servicios;
- dump de la base de datos.

Esto permitió trabajar con una copia funcional de la plataforma sin seguir interviniendo el sistema fuente.

---

## 4. Manejo de secretos y datos sensibles

### 4.1. Exclusión de contraseñas reales en GitHub

El repositorio público fue sanitizado para evitar la publicación de:

- contraseñas reales;
- secretos en texto plano;
- tokens;
- dumps reales de base de datos;
- configuraciones completas con información sensible.

### 4.2. Uso de archivos de ejemplo

En lugar del secreto real, se publicó un archivo de referencia:

- `secret-example.yaml`

Este archivo conserva la estructura necesaria para entender el despliegue, pero reemplaza los valores reales por placeholders.

### 4.3. Exclusión del dump real

Aunque el dump de la base fue esencial para la restauración local, este no fue incluido en el repositorio público. La razón es que puede contener:

- datos del entorno original;
- configuraciones internas;
- referencias funcionales del sistema fuente.

### 4.4. Revisión manual de documentación y evidencias

Se consideró necesario revisar que los documentos y pantallazos no expusieran:

- contraseñas visibles;
- tokens;
- rutas privadas;
- información sensible del entorno fuente.

---

## 5. Seguridad en Kubernetes local

### 5.1. Separación de componentes

La solución se desplegó separando:

- Keycloak;
- PostgreSQL;
- configuración sensible;
- persistencia.

Esto permitió una arquitectura local más ordenada y alineada con buenas prácticas.

### 5.2. Uso de Secret

La configuración sensible fue trasladada a un `Secret` de Kubernetes, evitando hardcodear credenciales directamente dentro de los deployments.

### 5.3. Persistencia controlada

El uso de `PersistentVolumeClaim` permitió controlar el almacenamiento de la base de datos y evitar pérdida accidental de información entre reinicios del pod.

### 5.4. Probes de salud

Se definieron probes de `readiness` y `liveness` para asegurar que Kubernetes validara correctamente el estado de Keycloak y PostgreSQL. Esto ayudó a detectar fallos de inicialización y a estabilizar la plataforma.

---

## 6. Riesgos identificados durante la migración

### 6.1. Riesgo de asumir configuraciones sin validación directa

La prueba mostró que no toda la información inicial podía tomarse como verdad absoluta. Fue necesario validar directamente en la VM la configuración efectiva del entorno.

### 6.2. Riesgo de restaurar comportamiento heredado desde la base de datos

Al restaurar la base completa de Keycloak, parte de la configuración del entorno original quedó persistida. El caso más importante fue el atributo `frontendUrl`, que provocó redireccionamientos heredados al dominio fuente.

### 6.3. Riesgo de exposición accidental en GitHub

Si no se sanitizaban los archivos antes de publicar el repositorio, existía riesgo de exponer:

- credenciales de base de datos;
- archivos de configuración con secretos;
- dumps reales;
- detalles internos del entorno fuente.

---

## 7. Control aplicado sobre el hallazgo de `frontendUrl`

Uno de los aspectos más relevantes desde la perspectiva de seguridad y control de configuración fue la identificación del atributo `frontendUrl` persistido en la base restaurada.

### Riesgo asociado

Este valor seguía apuntando al dominio del entorno original, lo que generaba:

- redireccionamientos no deseados;
- comportamiento inconsistente entre entorno local y acceso externo;
- dependencia funcional de una referencia heredada del entorno fuente.

### Medida aplicada

Se identificó el registro en la tabla `realm_attribute` y se eliminó del entorno restaurado, permitiendo que Keycloak resolviera correctamente las URLs en el nuevo contexto.

### Resultado

Con esta corrección:

- se eliminó la dependencia del dominio heredado;
- se estabilizó el comportamiento del acceso;
- y se validó correctamente tanto el acceso local como el acceso externo.

---

## 8. Consideraciones sobre publicación externa

### 8.1. Validación externa controlada

Se utilizaron mecanismos de exposición pública temporal exclusivamente con fines de validación técnica.

### 8.2. Protección del acceso administrativo

El panel administrativo de Keycloak es un componente sensible. Por ese motivo, la publicación externa se trató como una prueba de verificación y no como una propuesta final de arquitectura productiva.

### 8.3. Alcance de la validación

La exposición pública se utilizó para comprobar que:

- la aplicación era alcanzable externamente;
- la resolución de URLs funcionaba correctamente;
- y la plataforma podía validarse fuera del entorno local una vez corregida la configuración heredada.

---

## 9. Controles aplicados

Los principales controles implementados durante la prueba fueron:

- respaldo previo a cualquier intervención importante;
- uso de entorno local independiente para la migración;
- exclusión de secretos en el repositorio público;
- uso de `Secret` en Kubernetes;
- publicación de archivos de ejemplo en lugar de archivos reales;
- revisión de configuración persistida en la base restaurada;
- documentación explícita de hallazgos y decisiones técnicas.

---

## 10. Recomendaciones de mejora futura

Si esta solución evolucionara más allá del alcance de la prueba, se recomienda incorporar:

- gestión formal de secretos;
- `Ingress` con control de exposición;
- TLS administrado de forma explícita;
- políticas más robustas para acceso administrativo;
- automatización de despliegue;
- revisión adicional de parámetros del realm restaurado antes de pasar a validación final.

---

## 11. Conclusión

Desde el punto de vista de seguridad, la ejecución de la prueba fue abordada de manera responsable, priorizando la protección del entorno original, el uso controlado de respaldos y la publicación sanitizada de la solución. La identificación del atributo `frontendUrl` como configuración heredada fue especialmente relevante, ya que permitió resolver un comportamiento no deseado sin comprometer la estabilidad de la plataforma.

En consecuencia, la solución final no solo quedó funcional, sino también documentada de forma prudente en el manejo de información sensible, riesgos y controles aplicados.
