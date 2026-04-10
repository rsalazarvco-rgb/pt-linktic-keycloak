# Hallazgos técnicos, diferencias encontradas y limitaciones observadas

## 1. Propósito del documento

Este documento consolida los principales hallazgos técnicos identificados durante la ejecución de la prueba, incluyendo diferencias entre la información inicialmente esperada y la encontrada en el entorno real, procedimientos adicionales que fue necesario incorporar para resolver la migración, así como fallas o limitaciones que no pudieron resolverse completamente por razones de compatibilidad, comportamiento de la plataforma o particularidades del acceso externo.

---

## 2. Hallazgos sobre el entorno original

### 2.1. El despliegue no correspondía a un Keycloak legacy basado en WildFly/JBoss

Durante la fase inicial de reconocimiento se identificó que la instalación origen no correspondía a una versión legacy de Keycloak basada en WildFly/JBoss, sino a una versión moderna basada en Quarkus. Esto se evidenció por el uso de `kc.sh`, el arranque con `QuarkusEntryPoint`, la estructura de configuración bajo `conf/` y la ausencia de elementos típicos como `standalone.xml`. Esta diferencia fue relevante porque obligó a replantear la estrategia de contenerización y a descartar un enfoque centrado en rescatar configuraciones de WildFly. :contentReference[oaicite:0]{index=0}

### 2.2. La versión real de Keycloak fue superior a la inferida inicialmente

La verificación directa del entorno mostró que la versión efectiva de la plataforma era **Keycloak 26.6.0**, ejecutándose sobre **Java 25.0.2**. Esta combinación no podía asumirse sin inspección directa y fue determinante para construir una imagen coherente con el entorno original. La identificación precisa de estas versiones evitó una migración inconsistente por desacople entre runtime, configuración y binarios. 

### 2.3. El motor de base de datos real era PostgreSQL y la base funcional era `keycloak`

La base de datos funcional usada por la aplicación fue confirmada como **PostgreSQL**, y la base restaurada correspondió a **`keycloak`**. La validación de la restauración mostró finalmente **90 tablas** en el esquema `public`, confirmando que el dump sí representaba una base funcional completa y no una exportación parcial. 

### 2.4. La publicación original dependía de un reverse proxy externo

La solución original no exponía TLS directamente desde Keycloak. La terminación HTTPS estaba delegada a **Caddy**, mientras Keycloak operaba internamente por HTTP. Esto fue importante porque demostró que la publicación externa original dependía de una capa adicional de proxy y no de certificados directamente gestionados por la aplicación. :contentReference[oaicite:3]{index=3}

---

## 3. Diferencias encontradas entre lo esperado y lo observado

### 3.1. Diferencia entre credenciales iniciales y credenciales efectivas del entorno

Durante el análisis se observó una diferencia entre las credenciales presentes en el archivo de configuración suministrado inicialmente y las credenciales efectivamente utilizadas por la instancia en ejecución. Esto obligó a tratar la información extraída directamente de la VM como fuente de verdad, en lugar de asumir que el archivo inicial representaba el estado exacto del entorno operativo.

### 3.2. Redireccionamiento persistente al dominio original del entorno legado

Aunque el `Deployment` local de Kubernetes ya no definía un `hostname` explícito, el acceso por `localhost` seguía redirigiendo al dominio original `54-204-127-32.sslip.io`. La causa real no estaba en Kubernetes, sino en la configuración persistida dentro de la base restaurada, específicamente en el atributo `frontendUrl` del realm. Este hallazgo confirmó que una parte importante del comportamiento de Keycloak depende no solo de los manifiestos de despliegue, sino también de configuraciones almacenadas en la propia base de datos. :contentReference[oaicite:4]{index=4}

### 3.3. Diferencia entre el puerto funcional de la aplicación y el puerto de health/management

La aplicación web de Keycloak quedó disponible en el puerto **8080**, mientras que los endpoints de health/management quedaron disponibles en el puerto **9000**. Inicialmente se intentó validar salud sobre el puerto de aplicación, lo que generó un estado `0/1 Running` aunque el proceso estuviera arrancando. Fue necesario ajustar las probes de Kubernetes para que apuntaran al puerto correcto de management.

### 3.4. Comportamiento distinto entre acceso local y acceso público

La validación local por `localhost` resultó funcional, incluyendo el ingreso al admin console, mientras que el acceso externo mediante túneles seguros llegó a la aplicación pero presentó un error asociado al flujo del iframe/cookies del navegador. Esto evidenció una diferencia de comportamiento entre entorno local y acceso público, aun cuando la instancia y la base de datos ya estaban operativas. 

---

## 4. Procedimientos adicionales que fue necesario incorporar

### 4.1. Extracción controlada del entorno original antes de cualquier cambio

Fue necesario establecer como práctica inicial una fase estricta de **solo lectura y respaldo**, evitando modificar el entorno origen antes de entender completamente:

- versión de Keycloak,
- versión de Java,
- puertos,
- base de datos,
- archivos críticos,
- y publicación mediante proxy.

Esto redujo el riesgo de alterar una plataforma aún no comprendida completamente.

### 4.2. Respaldo explícito de artefactos operativos y no solo de la base de datos

La migración no podía resolverse únicamente con el dump de PostgreSQL. Fue necesario respaldar también:

- `keycloak.conf`,
- `cache-ispn.xml`,
- `Caddyfile`,
- definiciones de servicios,
- parámetros de arranque,
- y evidencia del comportamiento original.

Este procedimiento adicional permitió reconstruir no solo los datos, sino también el comportamiento esperado del sistema.

### 4.3. Creación de una imagen propia en lugar de depender solo de una imagen pública

Aunque existía una imagen oficial de Keycloak, la prueba exigía una solución propia y reproducible. Por ello fue necesario construir una imagen personalizada, incorporar el `cache-ispn.xml` y reproducir el comportamiento de build observado en el entorno original. Este procedimiento permitió alinear mejor el nuevo runtime con la lógica del despliegue fuente. :contentReference[oaicite:6]{index=6}

### 4.4. Ajuste de la ruta de persistencia para PostgreSQL 18

Uno de los procedimientos adicionales más relevantes fue la corrección del `mountPath` para PostgreSQL 18. La imagen de PostgreSQL 18 requiere una convención de almacenamiento diferente a versiones anteriores, y el uso de la ruta tradicional provocó errores de inicialización. Fue necesario adaptar la ruta de persistencia para que el contenedor aceptara correctamente el volumen y pudiera ejecutar la restauración del dump.

### 4.5. Reinicialización controlada del PVC para asegurar restauración real del dump

En una fase intermedia, el contenedor de PostgreSQL arrancaba correctamente, pero la base seguía vacía porque el volumen ya contenía datos parciales y la inicialización del dump era omitida. Fue necesario borrar y recrear el `PersistentVolumeClaim`, junto con el `ConfigMap` del SQL, para forzar una restauración limpia y verificable.

### 4.6. Ajuste de probes a la interfaz real de management

Aunque Keycloak iniciaba correctamente, Kubernetes no lo consideraba listo. Fue necesario identificar que la aplicación escuchaba en `8080`, pero la health interface estaba en `9000`, y adaptar `readinessProbe` y `livenessProbe` a ese puerto. Sin este procedimiento adicional, el pod seguía inestable desde la perspectiva del orquestador.

### 4.7. Corrección del atributo `frontendUrl` en la base restaurada

Para resolver el redireccionamiento hacia el dominio original, fue necesario realizar una consulta directa a la base restaurada y ubicar el valor `frontendUrl` persistido en `realm_attribute`. Esta corrección fue necesaria porque el comportamiento observado no se explicaba ya por los manifiestos de Kubernetes ni por los argumentos de arranque, sino por configuración almacenada en el propio realm.

---

## 5. Problemas o fallas que no pudieron resolverse completamente

### 5.1. Acceso administrativo externo con error de iframe/cookies

La principal limitación no resuelta fue el acceso al admin console desde una URL pública temporal. Tanto con ngrok como con cloudflared, la conectividad hasta la aplicación fue exitosa, pero el acceso administrativo externo presentó el mensaje relacionado con verificación por iframe/cookies. Esto demuestra que la aplicación era alcanzable, pero el flujo web del admin console no se comportó de forma estable bajo acceso externo temporal. La repetición del mismo error con ambos proveedores de túnel permitió concluir que no se trataba de un problema particular del túnel, sino de la interacción entre el admin console, el navegador y su validación web. 

### 5.2. Imposibilidad de mantener simultáneamente una experiencia perfecta en localhost y en dominio público temporal sin más cambios estructurales

Cuando se intentó alinear Keycloak a una URL pública temporal, el acceso local dejó de comportarse como entorno principal. Cuando se priorizó `localhost`, la validación pública volvió a presentar limitaciones del flujo administrativo. Esto evidenció que una solución completamente transparente para ambos contextos habría requerido ajustes adicionales más profundos sobre el modelo de hostname, publicación o capa de acceso, que excedían el objetivo principal de la prueba y podían comprometer la estabilidad ya alcanzada.

### 5.3. Comportamiento transitorio del admin console durante exposición pública

La publicación externa sí llegó a la aplicación, pero no pudo consolidarse una experiencia administrativa estable y universalmente compatible en navegadores externos sin seguir modificando una solución que ya se encontraba funcional localmente. Por esa razón, esta condición se dejó documentada como observación técnica y no se siguió interviniendo la plataforma.

---

## 6. Estado final alcanzado

A pesar de las limitaciones descritas, el resultado final fue satisfactorio en los aspectos principales de la prueba:

- análisis completo del entorno legado;
- identificación correcta de versiones y componentes;
- respaldo de configuración y base de datos;
- restauración íntegra de PostgreSQL;
- despliegue funcional de Keycloak en Kubernetes local;
- acceso exitoso al admin console en entorno local;
- publicación del resultado en repositorio GitHub sanitizado.

En consecuencia, las fallas remanentes quedaron circunscritas al acceso administrativo externo mediante túneles temporales, mientras que la migración, la restauración y la operación local fueron resueltas con éxito.

---

## 7. Conclusión de hallazgos

El proceso mostró que una migración exitosa de Keycloak no depende únicamente de reconstruir contenedores o restaurar una base de datos, sino de entender cómo interactúan la configuración persistida del realm, el runtime de Keycloak moderno, el modelo de persistencia de PostgreSQL y la forma en que la aplicación es publicada detrás de proxies o túneles. La mayor parte de las incidencias no surgieron por fallos básicos de despliegue, sino por diferencias finas entre el comportamiento esperado y el real del entorno restaurado.

La solución final quedó técnicamente operativa y estable en entorno local. Las diferencias, procedimientos adicionales y limitaciones documentadas en este archivo explican por qué fue necesario ir más allá de un despliegue estándar y aplicar validaciones específicas para alcanzar el resultado funcional obtenido.
