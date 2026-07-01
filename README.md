# Innovatech - Sistema de Gestión de Despachos

Aplicación empresarial para la gestión de órdenes de compra y despachos de la empresa **Innovatech Chile**. 
Sistema basado en microservicios con frontend React, backend Spring Boot, base de datos MySQL y despliegue automatizado 
en AWS EC2 mediante Docker y GitHub Actions CI/CD.

---

## Arquitectura del Sistema

```
                     ┌─────────────────────────────────────────────┐
                     │            Navegador Web (puerto 80)         │
                     └──────────────────────┬──────────────────────┘
                                            │
                                            ▼
                  ┌─────────────────────────────────────────────────┐
                  │           EC2 Frontend (Pública)                │
                  │  ┌───────────────────────────────────────────┐  │
                  │  │  Nginx (front_despacho)                   │  │
                  │  │  └─ Sirve SPA React en /                  │  │
                  │  │  └─ Proxy /api/v1/ventas   → back-ventas  │  │
                  │  │  └─ Proxy /api/v1/despachos → back-desp.  │  │
                  │  └───────────────────────────────────────────┘  │
                  └──────────────────────┬──────────────────────────┘
                                         │
                                    (VPC Privada)
                                         │
                  ┌──────────────────────┴──────────────────────────┐
                  │           EC2 Backend (Privada)                 │
                  │  ┌───────────────────────────────────────────┐  │
                  │  │  back-ventas (Spring Boot :8080)          │  │
                  │  │  API: /api/v1/ventas (CRUD Ventas)        │  │
                  │  └───────────────────────────────────────────┘  │
                  │  ┌───────────────────────────────────────────┐  │
                  │  │  back-despachos (Spring Boot :8081)       │  │
                  │  │  API: /api/v1/despachos (CRUD Despachos)  │  │
                  │  └───────────────────────────────────────────┘  │
                  │  ┌───────────────────────────────────────────┐  │
                  │  │  MySQL 8.4 (:3306)                        │  │
                  │  │  Base de datos: innovatech                │  │
                  │  │  Volumen persistente: mysql_data          │  │
                  │  └───────────────────────────────────────────┘  │
                  └────────────────────────────────────────────────┘
```

### Flujo de Datos

1. El usuario accede al Frontend vía IP pública o dominio de la instancia EC2 Frontend
2. Nginx sirve la SPA React y hace proxy inverso de las peticiones API
3. `/api/v1/ventas` → proxy hacia `back-ventas:8080` en la subred privada
4. `/api/v1/despachos` → proxy hacia `back-despachos:8081` en la subred privada
5. Ambos backends se conectan a MySQL para persistencia de datos

---

## Estructura del Proyecto

```
proyecto_semestral/
├── .github/workflows/                  # Pipelines CI/CD
│   ├── frontend-deploy.yml
│   ├── backend-ventas-deploy.yml
│   └── backend-despachos-deploy.yml
├── deploy/                             # Archivos de despliegue para EC2
│   ├── backend/
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   └── frontend/
│       ├── docker-compose.yml
│       └── .env.example
├── back-Ventas_SpringBoot/             # Microservicio Ventas
│   └── Springboot-API-REST/
│       ├── Dockerfile                  # Multi-stage, usuario no root
│       ├── pom.xml
│       └── src/
├── back-Despachos_SpringBoot/          # Microservicio Despachos
│   └── Springboot-API-REST-DESPACHO/
│       ├── Dockerfile                  # Multi-stage, usuario no root
│       ├── pom.xml
│       └── src/
├── front_despacho/                     # Frontend React + Vite
│   ├── Dockerfile                      # Multi-stage, nginx no root
│   ├── nginx.conf.template             # Proxy reverso con env vars
│   └── src/
├── aws/                                # Scripts de infraestructura AWS para ECS
│   ├── setup-infra.sh                  #   Orquestador principal
│   ├── 01-vpc.sh                       #   VPC y subredes
│   ├── 02-ecr.sh                       #   Repositorios ECR
│   ├── 03-security-groups.sh           #   4 Security Groups
│   ├── 04-iam-roles.sh                 #   Roles IAM para ECS
│   ├── 05-cloudwatch.sh                #   Log Groups CloudWatch
│   ├── 06-ecs-cluster.sh               #   Cluster ECS + Service Discovery
│   ├── 07-alb.sh                       #   ALB, Target Groups y reglas
│   ├── 08-ecs-services.sh              #   Task Definitions y ECS Services
│   └── task-definitions/               #   Definiciones JSON de tareas
│       ├── frontend-task.json
│       ├── back-ventas-task.json
│       ├── back-despachos-task.json
│       └── mysql-task.json
├── docker-compose.yml                  # Orquestador local (desarrollo)
├── .env                                # Variables de entorno locales
├── .env.example                        # Template de variables
├── .gitignore
├── INTRUCCIONES MANUALES.docx          # Instrucciones manuales para EP3
└── README.md
```

---

## Requisitos

- Docker Desktop 24+ y Docker Compose v2+
- AWS CLI configurado (para despliegue en EC2)
- Cuenta AWS Academy Learner Lab (o cuenta AWS propia)
- Git

---

## Ejecución Local (Desarrollo)

```bash
# 1. Clonar el repositorio
git clone <url-repositorio>
cd proyecto_semestral

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con las credenciales deseadas

# 3. Levantar todos los servicios
docker compose up -d

# 4. Verificar que los servicios están funcionando
docker compose ps

# 5. Acceder a la aplicación
# Frontend: http://localhost
# API Ventas: http://localhost:8080/api/v1/ventas
# API Despachos: http://localhost:8081/api/v1/despachos
# Swagger Ventas: http://localhost:8080/swagger-ui.html
# Swagger Despachos: http://localhost:8081/swagger-ui.html

# 6. Detener servicios
docker compose down

# 7. Detener servicios y eliminar volúmenes (borra datos)
docker compose down -v
```

---

## Despliegue en AWS EC2

### 1. Pre-requisitos en AWS

```bash
# Crear repositorios ECR (3)
aws ecr create-repository --repository-name front-despacho
aws ecr create-repository --repository-name back-ventas
aws ecr create-repository --repository-name back-despachos
```

### 2. Configurar Instancias EC2

| Instancia | Subred | SG - Puertos | Rol |
|-----------|--------|-------------|-----|
| Frontend | Pública | HTTP(80): 0.0.0.0/0, SSH(22): IP laboratorio | Sirve frontend React |
| Backend | Privada | TCP(8080): Frontend SG, TCP(8081): Frontend SG, SSH(22): IP laboratorio | Backends + MySQL |
| Nota | | MySQL (3306) no se expone externamente. La comunicación es interna mediante la red Docker entre contenedores en la misma instancia. | |

**Script de User Data** (para ambas instancias):
```bash
#!/bin/bash
yum update -y
yum install -y docker aws-cli
systemctl enable docker
systemctl start docker
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
usermod -aG docker ec2-user
```

### 3. Configurar GitHub Secrets

Agregar en Settings → Secrets and variables → Actions:

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Access key de IAM (Lab temporales) |
| `AWS_SECRET_ACCESS_KEY` | Secret key correspondiente |
| `AWS_SESSION_TOKEN` | Session token (obligatorio en AWS Academy Learner Lab) |
| `AWS_REGION` | Región AWS (ej: us-east-1) |
| `ECR_REGISTRY` | URI del registry ECR (ej: 123456.dkr.ecr.us-east-1.amazonaws.com) |
| `EC2_FRONTEND_HOST` | IP pública de la instancia Frontend |
| `EC2_BACKEND_HOST` | IP privada de la instancia Backend |
| `EC2_SSH_KEY` | Contenido completo del archivo .pem |
| `BACKEND_PRIVATE_IP` | IP privada del backend (para frontend deploy) |
| `DB_NAME` | `innovatech` |
| `DB_USERNAME` | `appuser` |
| `DB_PASSWORD` | Contraseña de base de datos |
| `MYSQL_ROOT_PASSWORD` | Contraseña root de MySQL |

### 4. Despliegue Manual (alternativa sin CI/CD)

```bash
# En la instancia Backend:
mkdir -p /home/ec2-user/deploy/backend
# Copiar deploy/backend/docker-compose.yml y .env
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REGISTRY>
cd /home/ec2-user/deploy/backend
export ECR_REGISTRY=<account>.dkr.ecr.us-east-1.amazonaws.com
export DB_NAME=innovatech DB_USERNAME=appuser DB_PASSWORD=<pass> MYSQL_ROOT_PASSWORD=<pass>
docker compose up -d

# En la instancia Frontend:
mkdir -p /home/ec2-user/deploy/frontend
# Copiar deploy/frontend/docker-compose.yml y .env
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REGISTRY>
cd /home/ec2-user/deploy/frontend
export ECR_REGISTRY=<account>.dkr.ecr.us-east-1.amazonaws.com
export BACKEND_HOST=<ip-privada-backend>
docker compose up -d
```

### 5. CI/CD Automático (EP2 - EC2)

El pipeline se activa automáticamente con cada `push` a la rama `deploy`:
1. **Build**: Construye la imagen Docker multi-stage
2. **Push**: Publica la imagen en Amazon ECR
3. **Deploy**: Conecta por SSH a EC2, actualiza la imagen y reinicia contenedores

```bash
git checkout deploy
git add .
git commit -m "feat: actualiza servicio"
git push origin deploy
# El pipeline se ejecuta automáticamente en GitHub Actions
```

### 6. CI/CD Automático (EP3 - ECS Fargate)

El pipeline para ECS sigue el mismo trigger pero despliega en ECS:

```bash
git checkout deploy
git add .
git commit -m "feat: actualiza servicio ECS"
git push origin deploy
```

**Flujo ECS:** `[Push a deploy] → [Checkout] → [Login ECR] → [Build Docker] → [Push a ECR] → [ECS update-service --force-new-deployment]`

---

## Despliegue en AWS ECS (EP3)

### Arquitectura ECS + Fargate + ALB

```
                      ┌─────────────────────────────────────────────┐
                      │            Navegador Web (puerto 80)         │
                      └──────────────────────┬──────────────────────┘
                                             │
                                             ▼
               ┌─────────────────────────────────────────────────────┐
               │           ALB - alb-innovatech (público)            │
               │  Reglas path-based:                                 │
               │  ├── /                  → tg-frontend:8080          │
               │  ├── /api/v1/ventas*    → tg-back-ventas:8080      │
               │  └── /api/v1/despachos* → tg-back-despachos:8081    │
               └──────────────┬──────────────────────┬───────────────┘
                              │                      │
                     (SG Frontend)             (SG Backend)
                              │                      │
               ┌──────────────▼──────┐   ┌───────────▼──────────────┐
               │  frontend-service   │   │  back-ventas-service     │
               │  Fargate :8080      │   │  Fargate :8080           │
               │  ECS Fargate        │   │  ECS Fargate             │
               └─────────────────────┘   └───────────┬──────────────┘
                                                      │
                                              (SG MySQL)
                                                      │
                                               ┌──────▼──────┐
                                               │ mysql-service│
                                               │ Fargate :3306│
                                               │ innovatech   │
                                               └─────────────┘
```

### Servicios ECS (Fargate)

| Servicio | Puerto | Target Group | Health Check |
|----------|--------|-------------|--------------|
| frontend-service | 8080 | tg-frontend | `/` |
| back-ventas-service | 8080 | tg-back-ventas | `/actuator/health` |
| back-despachos-service | 8081 | tg-back-despachos | `/actuator/health` |
| mysql-service | 3306 | (sin ALB) | mysqladmin ping |

### Infraestructura AWS

| Recurso | Nombre | Descripción |
|---------|--------|-------------|
| VPC | default o innovatech-vpc | 2 subredes públicas (us-east-1a, us-east-1b) |
| ALB | alb-innovatech | Internet-facing, HTTP:80 |
| Cluster ECS | innovatech-cluster | Fargate, us-east-1 |
| Service Discovery | innovatech.local | DNS privado: mysql.innovatech.local |
| ECR | front-despacho, back-ventas, back-despachos | Repositorios privados |

### Automatización (Scripts AWS CLI)

Los scripts en `aws/` automatizan toda la infraestructura:

```bash
# 1. Configurar credenciales AWS Academy
aws configure

# 2. Ejecutar script principal
bash aws/setup-infra.sh

# 3. (Opcional) Pasos individuales
bash aws/01-vpc.sh
bash aws/02-ecr.sh
bash aws/03-security-groups.sh
bash aws/04-iam-roles.sh
bash aws/05-cloudwatch.sh
bash aws/06-ecs-cluster.sh
bash aws/07-alb.sh

# 4. Después de hacer push de imágenes a ECR:
bash aws/08-ecs-services.sh
```

---

## Contenedorización

## Contenedorización

### Dockerfile - Multi-stage Build

Cada servicio utiliza Dockerfile multi-stage para optimizar el tamaño de la imagen final:

| Servicio | Stage Build | Stage Final | Puerto | Usuario |
|----------|-------------|-------------|--------|---------|
| front-despacho | `node:24-alpine` | `nginxinc/nginx-unprivileged:1.27-alpine` | 8080 | no root (nginx) |
| back-ventas | `maven:3.9-eclipse-temurin-17-alpine` | `eclipse-temurin:17-jre-alpine` | 8080 | no root (spring) |
| back-despachos | `maven:3.9-eclipse-temurin-17-alpine` | `eclipse-temurin:17-jre-alpine` | 8081 | no root (spring) |

**Beneficios del multi-stage:**
- **Reducción de tamaño**: La imagen final solo contiene lo necesario para ejecutar (JRE, no JDK; binarios compilados, no código fuente)
- **Seguridad**: Menor superficie de ataque al eliminar herramientas de build del contenedor final
- **Usuario no root**: Principio de mínimo privilegio para evitar escalación de permisos
- **Capas limpias**: Dependencias primero (cambian menos), código después (cambia más) → mejor cacheo

### docker-compose.yml

El archivo `docker-compose.yml` orquesta 4 servicios en una red bridge interna `innovatech_net`:

| Servicio | Imagen/Contexto | Dependencias | Puertos |
|----------|----------------|--------------|---------|
| mysql | `mysql:8.4` | - | - |
| back-ventas | Build local / ECR | mysql (health) | 8080:8080 |
| back-despachos | Build local / ECR | mysql (health) | 8081:8081 |
| frontend | Build local / ECR | back-ventas, back-despachos | 80:8080 |

La red bridge `innovatech_net` permite la comunicación entre contenedores por nombre de servicio.

---

## Persistencia de Datos

Se utiliza un **named volume** (`mysql_data`) para la persistencia de la base de datos MySQL.

```yaml
volumes:
  mysql_data:

services:
  mysql:
    volumes:
      - mysql_data:/var/lib/mysql
```

**¿Por qué named volume y no bind mount?**

| Característica | Named Volume | Bind Mount |
|----------------|-------------|------------|
| Gestión por Docker | ✅ Docker lo administra | ❌ Depende del SO host |
| Portabilidad | ✅ Funciona en cualquier SO | ❌ Rutas absolutas del host |
| Seguridad | ✅ No expone estructura host | ⚠️ Acceso directo a sistema archivos |
| Backup/Restore | ✅ `docker run --volumes-from` | ⚠️ Copia manual de archivos |
| Rendimiento | ✅ Nativo del driver Docker | ✅ Similar |

**Justificación**: Elegimos named volume porque:
1. Docker administra el ciclo de vida del volumen, no requiere rutas absolutas
2. Funciona idéntico en Windows, macOS y Linux
3. Los datos sobreviven reinicios de contenedores (`docker compose down` no elimina volúmenes)
4. Facilita backups con `docker run --rm -v mysql_data:/data -v $(pwd):/backup alpine tar czf /backup/mysql_backup.tar.gz -C /data .`

---

## Pipeline CI/CD (GitHub Actions)

### Flujo del Pipeline (EP2 - EC2)

```
[Push a rama deploy] → [Checkout] → [Login ECR] → [Build Docker] → [Push a ECR] → [SSH a EC2] → [Pull imagen] → [docker compose up]
```

### Flujo del Pipeline (EP3 - ECS Fargate)

```
[Push a rama deploy] → [Checkout] → [Login ECR] → [Build Docker] → [Push a ECR] → [ECS update-service]
```

### Triggers

Cada pipeline se activa exclusivamente con `push` en la rama `deploy` y cambios en la carpeta correspondiente:

| Pipeline | Path Trigger |
|----------|-------------|
| Frontend | `front_despacho/**` |
| Backend Ventas | `back-Ventas_SpringBoot/**` |
| Backend Despachos | `back-Despachos_SpringBoot/**` |

### Secrets Utilizados (EP3 - ECS)

| Secret | Descripción | ¿Obligatorio? |
|--------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | Access key de IAM (Lab temporales) | Sí |
| `AWS_SECRET_ACCESS_KEY` | Secret key correspondiente | Sí |
| `AWS_SESSION_TOKEN` | Session token (obligatorio en AWS Academy) | Sí |
| `AWS_REGION` | Región AWS (ej: us-east-1) | Sí |

> **Nota**: `ECR_REGISTRY` y `ECS_CLUSTER` **no** se configuran como secrets.  
> `ECR_REGISTRY` se obtiene dinámicamente del paso `login-ecr` en el workflow.  
> `ECS_CLUSTER` está hardcodeado como `innovatech-cluster` en cada workflow.  
> Las credenciales de BD (`DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`, `MYSQL_ROOT_PASSWORD`) se pasan como variables de entorno en las Task Definitions, no como secrets de GitHub.

### Justificación Técnica

- **ECS Fargate vs EC2**: Fargate elimina la administración de servidores; AWS gestiona la infraestructura subyacente. Escalabilidad horizontal automática. Menor superficie de ataque al no tener que gestionar parches del SO.
- **ALB con path-based routing**: Un solo ALB público enruta el tráfico según la ruta URL, eliminando la necesidad de Nginx como proxy inverso y simplificando la arquitectura.
- **Service Discovery (Cloud Map)**: Los backends descubren MySQL por DNS interno (`mysql.innovatech.local`) sin necesidad de IPs fijas ni variables de entorno complejas.
- **Registro ECR vs Docker Hub**: Amazon ECR por integración nativa con IAM, sin rate limits.
- **Rama `deploy`**: Aislamos el pipeline de producción en una rama específica.

---

## Principios DevOps Aplicados

### 1. Contenedorización (Docker)
- Estandarización de entornos: mismo contenedor en dev, test y producción
- Aislamiento de dependencias por servicio
- Imágenes inmutables para despliegues reproducibles

### 2. Integración Continua (CI)
- Build y test automáticos en cada push a deploy
- Detección temprana de errores de compilación
- Garantía de que la imagen Docker se construye correctamente

### 3. Despliegue Continuo (CD)
- Actualización automática de instancias EC2
- Zero-downtime planning (contenedores se reinician con nueva imagen)
- Trazabilidad: cada despliegue corresponde a un commit específico

### 4. Control de Versiones (Git)
- Ramas protegidas (deploy como rama de producción)
- Commits descriptivos con convención semántica
- Historial completo de cambios y responsables

### 5. Gestión de Configuración
- Variables de entorno externalizadas (no hardcodeadas)
- `.env.example` como documentación viva de configuración
- Secrets en GitHub para credenciales sensibles

### 6. Persistencia con Volúmenes
- Datos críticos separados del ciclo de vida del contenedor
- Named volumes para portabilidad entre entornos
- Backup y restore simplificados

---

## APIs Disponibles

### Ventas API (`/api/v1/ventas`)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/v1/ventas` | Listar todas las ventas |
| GET | `/api/v1/ventas/{id}` | Obtener venta por ID |
| POST | `/api/v1/ventas` | Crear nueva venta |
| PUT | `/api/v1/ventas/{id}` | Actualizar venta |
| DELETE | `/api/v1/ventas/{id}` | Eliminar venta |

### Despachos API (`/api/v1/despachos`)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/v1/despachos` | Listar todos los despachos |
| GET | `/api/v1/despachos/{id}` | Obtener despacho por ID |
| POST | `/api/v1/despachos` | Crear nuevo despacho |
| PUT | `/api/v1/despachos/{id}` | Actualizar despacho |
| DELETE | `/api/v1/despachos/{id}` | Eliminar despacho |

### Documentación Swagger
- Ventas: `http://<host>:8080/swagger-ui.html`
- Despachos: `http://<host>:8081/swagger-ui.html`

---

## Consideraciones de Seguridad

- Usuarios no root en todos los contenedores (principio de mínimo privilegio)
- Variables sensibles (contraseñas) manejadas vía secrets de GitHub
- `.env` en `.gitignore` para evitar exponer credenciales
- `.dockerignore` configurado para excluir archivos innecesarios del contexto de build
- Security Groups siguiendo el principio de mínimo privilegio:
  - ALB: solo HTTP(80) desde internet
  - Frontend: solo TCP(8080) desde ALB
  - Backend: solo TCP(8080,8081) desde ALB
  - MySQL: solo TCP(3306) desde Backend
- MySQL (3306) nunca se expone externamente: solo los backends pueden alcanzarlo
- Tasks ECS corren con assignPublicIp=ENABLED pero los Security Groups bloquean acceso directo
- Roles IAM separados: Execution Role (solo para iniciar tareas) y Task Role (sin permisos extra)
- Logs centralizados en CloudWatch para auditoría y debugging
- Conexión MySQL con `useSSL=false` solo para entorno controlado (cambiar a `true` en producción)

---

## Resolución de Problemas

```bash
# Verificar logs de un servicio
docker compose logs -f <service-name>

# Verificar que los contenedores están corriendo
docker compose ps

# Verificar conectividad entre contenedores
docker exec -it front_despacho ping back-ventas

# Verificar variables de entorno en contenedor
docker exec front_despacho env | grep VENTAS

# Verificar que el volumen persiste datos
docker volume inspect proyecto-semestral_mysql_data

# Reconstruir imágenes sin caché
docker compose build --no-cache

# Limpiar recursos no usados
docker system prune -f

# En EC2, verificar que Docker está corriendo
sudo systemctl status docker
```
