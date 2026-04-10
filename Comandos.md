# Comandos ejecutados durante la prueba técnica

## 1. Propósito

Este documento consolida los principales comandos utilizados durante la ejecución de la prueba técnica, organizados por fases. Su finalidad es dejar trazabilidad del procedimiento aplicado, facilitar la reproducción técnica de la solución y apoyar la sustentación del trabajo realizado.

---

## 2. Fase de acceso y reconocimiento del entorno original

### 2.1. Conexión al servidor origen

Se estableció conexión al entorno fuente mediante SSH, usando los datos suministrados en la prueba.

```bash
ssh -i key.pem ec2-user@54.204.127.32
```

### 2.2. Identificación básica del entorno

Se ejecutaron comandos para reconocer el sistema operativo, el usuario activo y el contexto general de la máquina virtual.

```bash
hostname
whoami
pwd
cat /etc/os-release
```

### 2.3. Identificación del proceso de Keycloak

Se verificó cómo estaba ejecutándose Keycloak en el entorno original.

```bash
ps -ef | egrep -i "keycloak|java|jboss|wildfly" | grep -v grep
```

### 2.4. Identificación del servicio Keycloak

Se inspeccionó la definición del servicio en `systemd`.

```bash
sudo systemctl cat keycloak
```

### 2.5. Identificación del proxy original

Se revisó la configuración del proxy inverso utilizado en el entorno fuente.

```bash
sudo systemctl cat caddy
sudo sed -n '1,200p' /etc/caddy/Caddyfile
```

### 2.6. Identificación de versión de Keycloak y Java

Se validó la versión real de Keycloak y del runtime Java.

```bash
sudo /opt/keycloak/keycloak-system/bin/kc.sh --version
java -version
```

---

## 3. Fase de respaldo y extracción de artefactos

### 3.1. Respaldo de configuración principal

Se copió la configuración principal de Keycloak a una carpeta de trabajo.

```bash
mkdir -p ~/migration-backup/keycloak
sudo cp /opt/keycloak/keycloak-system/conf/keycloak.conf ~/migration-backup/keycloak/
sudo chown ec2-user:ec2-user ~/migration-backup/keycloak/keycloak.conf
```

### 3.2. Respaldo de configuración de caché

Se respaldó el archivo `cache-ispn.xml`.

```bash
sudo cp /opt/keycloak/keycloak-system/conf/cache-ispn.xml ~/migration-backup/keycloak/
```

### 3.3. Respaldo de configuración del proxy

Se respaldó el archivo `Caddyfile`.

```bash
mkdir -p ~/migration-backup/caddy
sudo cp /etc/caddy/Caddyfile ~/migration-backup/caddy/
sudo chown ec2-user:ec2-user ~/migration-backup/caddy/Caddyfile
```

### 3.4. Respaldo de definiciones de servicios

Se conservaron las definiciones de `systemd` como evidencia del entorno original.

```bash
sudo systemctl cat keycloak > ~/migration-backup/keycloak/keycloak.service.txt
sudo systemctl cat caddy > ~/migration-backup/caddy/caddy.service.txt
```

### 3.5. Validación de base de datos existente

Se verificaron las bases de datos disponibles.

```bash
PGPASSWORD='PASSWORD' psql -h localhost -U keycloak -d postgres -c '\l'
```

### 3.6. Exportación del dump de la base

Se generó el respaldo de la base `keycloak`.

```bash
mkdir -p ~/migration-backup/postgres
PGPASSWORD='PASSWORD' pg_dump -h localhost -U keycloak -d keycloak > ~/migration-backup/postgres/keycloak.sql
```

### 3.7. Validación del dump generado

Se revisó el tamaño y encabezado del archivo exportado.

```bash
ls -lh ~/migration-backup/postgres/keycloak.sql
head -n 20 ~/migration-backup/postgres/keycloak.sql
```

---

## 4. Fase de preparación del entorno local

### 4.1. Validación de Docker

Se validó el motor de contenedores local.

```powershell
docker version
docker ps
```

### 4.2. Validación de kubectl

Se verificó la instalación del cliente de Kubernetes.

```powershell
kubectl version --client
```

### 4.3. Validación de kind

Se confirmó la disponibilidad del gestor de clústeres locales.

```powershell
kind version
```

### 4.4. Creación del clúster local

Se creó el clúster local llamado `keycloak-lab`.

```powershell
kind create cluster --name keycloak-lab
```

### 4.5. Validación de nodos

Se verificó el estado del nodo del clúster.

```powershell
kubectl get nodes
```

---

## 5. Fase de construcción de imagen

### 5.1. Build de la imagen personalizada

Se construyó la imagen propia de Keycloak.

```powershell
docker build -t keycloak-custom:26.6.0 -f Dockerfile .
```

### 5.2. Carga de imagen al clúster kind

La imagen generada se cargó en el clúster local.

```powershell
kind load docker-image keycloak-custom:26.6.0 --name keycloak-lab
```

---

## 6. Fase de despliegue en Kubernetes

### 6.1. Aplicación de namespace

```powershell
kubectl apply -f k8s/namespace.yaml
```

### 6.2. Aplicación del secret

```powershell
kubectl apply -f k8s/secret-example.yaml
```

### 6.3. Aplicación del volumen persistente

```powershell
kubectl apply -f k8s/postgres-pvc.yaml
```

### 6.4. Aplicación de servicios

```powershell
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/keycloak-service.yaml
```

### 6.5. Aplicación de deployments

```powershell
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/keycloak-deployment.yaml
```

---

## 7. Fase de restauración de la base de datos

### 7.1. Creación del ConfigMap a partir del dump

El dump SQL fue cargado como `ConfigMap` para inicializar PostgreSQL.

```powershell
kubectl create configmap keycloak-db-init --from-file=C:\keycloak-migration\backup\postgres\keycloak.sql -n keycloak
```

### 7.2. Reinicialización del despliegue de PostgreSQL

Cuando fue necesario forzar una restauración limpia, se eliminaron recursos previos.

```powershell
kubectl delete deployment postgres -n keycloak
kubectl delete pvc postgres-pvc -n keycloak
kubectl delete configmap keycloak-db-init -n keycloak
```

### 7.3. Reaplicación de recursos

```powershell
kubectl create configmap keycloak-db-init --from-file=C:\keycloak-migration\backup\postgres\keycloak.sql -n keycloak
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
```

### 7.4. Revisión de logs de restauración

```powershell
kubectl logs -n keycloak deploy/postgres --tail=120
```

### 7.5. Validación de tablas restauradas

```powershell
kubectl exec -n keycloak deploy/postgres -- psql -U keycloak -d keycloak -c "select count(*) as total_tablas from information_schema.tables where table_schema='public';"
```

---

## 8. Fase de estabilización de Keycloak

### 8.1. Reinicio del deployment

```powershell
kubectl rollout restart deployment/keycloak -n keycloak
```

### 8.2. Seguimiento del estado de pods

```powershell
kubectl get pods -n keycloak -w
```

### 8.3. Revisión de logs de Keycloak

```powershell
kubectl logs -n keycloak deploy/keycloak --tail=80
```

### 8.4. Revisión del deployment aplicado

```powershell
kubectl get deployment keycloak -n keycloak -o yaml
```

---

## 9. Fase de validación funcional local

### 9.1. Validación del estado final de pods

```powershell
kubectl get pods -n keycloak
```

### 9.2. Validación de servicios

```powershell
kubectl get svc -n keycloak
```

### 9.3. Habilitación de acceso local

```powershell
kubectl port-forward -n keycloak deployment/keycloak 8080:8080
```

### 9.4. Validación local desde navegador

Acceso realizado mediante:

```text
http://localhost:8080
```

---

## 10. Fase de diagnóstico de redireccionamiento

### 10.1. Consulta de atributos del realm

Se inspeccionó la tabla `realm_attribute` para identificar configuraciones heredadas del entorno original.

```powershell
kubectl exec -n keycloak deploy/postgres -- psql -U keycloak -d keycloak -c "select * from realm_attribute where value like '%sslip.io%';"
```

### 10.2. Consulta de clientes con URL heredadas

```powershell
kubectl exec -n keycloak deploy/postgres -- psql -U keycloak -d keycloak -c "select id, name, root_url, base_url from client where root_url like '%sslip.io%' or base_url like '%sslip.io%';"
```

### 10.3. Actualización del `frontendUrl`

Se actualizó el valor del atributo `frontendUrl` para privilegiar el acceso local.

```powershell
kubectl exec -n keycloak deploy/postgres -- psql -U keycloak -d keycloak -c "update realm_attribute set value='http://localhost:8080' where name='frontendUrl';"
```

### 10.4. Validación de la actualización

```powershell
kubectl exec -n keycloak deploy/postgres -- psql -U keycloak -d keycloak -c "select * from realm_attribute where name='frontendUrl';"
```

---

## 11. Fase de exposición pública

### 11.1. Pruebas con ngrok

```powershell
ngrok http 8080
```

### 11.2. Pruebas con cloudflared

```powershell
cloudflared tunnel --url http://localhost:8080
```

### Resultado observado

En ambos casos, la conectividad pública llegó a la aplicación, pero el acceso administrativo externo presentó una limitación asociada al flujo de verificación por iframe/cookies del navegador.

---

## 12. Fase de publicación en GitHub

### 12.1. Inicialización del repositorio local

```bash
git init
```

### 12.2. Registro de archivos

```bash
git add .
```

### 12.3. Commit inicial

```bash
git commit -m "Initial delivery - Keycloak migration to local Kubernetes"
```

### 12.4. Asociación del remoto

```bash
git remote add origin https://github.com/rsalazarvco-rgb/pt-linktic-keycloak.git
```

### 12.5. Envío al repositorio

```bash
git branch -M main
git push -u origin main
```

---

## 13. Resultado final

Los comandos y procedimientos aplicados permitieron:

- analizar correctamente el entorno fuente;
- extraer configuración y datos;
- construir una imagen propia de Keycloak;
- restaurar la base de datos;
- desplegar la solución en Kubernetes local;
- validar el acceso funcional a Keycloak;
- publicar la entrega en GitHub.

Este documento deja trazabilidad operativa del proceso seguido y sirve como soporte de reproducción técnica de la solución.
