# Innovatech — Sistema de Gestión de Despachos

Proyecto compuesto por un frontend React, dos microservicios Spring Boot y una base de datos MySQL. Incluye ejecución local con Docker Compose, pipelines de GitHub Actions y scripts de infraestructura para Amazon ECS Fargate.

## Componentes

| Componente | Tecnología | Puerto |
|---|---|---:|
| Frontend | React, Vite y Nginx | 8080 en contenedor / 80 local |
| API de ventas | Spring Boot 3, Java 17 | 8080 |
| API de despachos | Spring Boot 3, Java 17 | 8081 |
| Base de datos | MySQL 8.4 | 3306 interno |

## Estructura

```text
.
├── .github/workflows/          # CI/CD hacia ECR y ECS
├── aws/                        # Infraestructura ECS/ALB/CloudWatch
│   └── task-definitions/       # Task definitions parametrizadas
├── back-Ventas_SpringBoot/     # Microservicio de ventas
├── back-Despachos_SpringBoot/  # Microservicio de despachos
├── front_despacho/             # Aplicación React
├── deploy/                     # Compose manual heredado para EC2
├── docker-compose.yml          # Entorno local completo
├── .env.example                # Variables locales de ejemplo
└── README.md
```

## Ejecución local

### Requisitos

- Docker Desktop o Docker Engine con Docker Compose v2.
- Puertos 80, 8080 y 8081 disponibles.

### Inicio

```bash
cp .env.example .env
```

Edita `.env` y reemplaza las contraseñas de ejemplo. Luego ejecuta:

```bash
docker compose up -d --build
docker compose ps
```

Endpoints:

- Frontend: `http://localhost`
- Ventas: `http://localhost:8080/api/v1/ventas`
- Despachos: `http://localhost:8081/api/v1/despachos`
- Swagger Ventas: `http://localhost:8080/swagger-ui.html`
- Swagger Despachos: `http://localhost:8081/swagger-ui.html`

Para detener el entorno sin borrar los datos:

```bash
docker compose down
```

Para eliminar también el volumen de MySQL:

```bash
docker compose down -v
```

> `mysql_data` es un volumen nombrado. Los datos sobreviven a `docker compose down`, pero se eliminan con `docker compose down -v`.

## Desarrollo sin Docker

### Frontend

```bash
cd front_despacho
npm ci
npm run lint
npm run dev
```

Vite redirige las APIs locales a los puertos 8080 y 8081.

### Backends

Configura estas variables antes de iniciar cada servicio:

```text
DB_ENDPOINT=localhost
DB_PORT=3306
DB_NAME=innovatech
DB_USERNAME=appuser
DB_PASSWORD=<contraseña>
```

Luego, desde la carpeta de cada proyecto Spring Boot:

```bash
./mvnw test
./mvnw spring-boot:run
```

## Flujo funcional

1. El frontend consulta las ventas sin despacho generado.
2. El usuario crea una orden de despacho asociada a una venta.
3. La venta se marca con `despachoGenerado=true`.
4. El usuario registra intentos y cambia el estado del despacho a entregado.

Rutas principales:

| Método | Ruta | Uso |
|---|---|---|
| GET / POST | `/api/v1/ventas` | Listar o crear ventas |
| GET / PUT / DELETE | `/api/v1/ventas/{id}` | Consultar, actualizar o eliminar una venta |
| GET / POST | `/api/v1/despachos` | Listar o crear despachos |
| GET / PUT / DELETE | `/api/v1/despachos/{id}` | Consultar, actualizar o eliminar un despacho |

## CI/CD con GitHub Actions

Los tres workflows se ejecutan con cambios en la rama `deploy`:

- `frontend-deploy.yml`
- `backend-ventas-deploy.yml`
- `backend-despachos-deploy.yml`

Cada pipeline valida el componente, construye y publica la imagen en Amazon ECR, ejecuta un escaneo informativo de vulnerabilidades con Trivy, fuerza el despliegue, espera que ECS quede estable y realiza un smoke test del endpoint público correspondiente. El escaneo informa hallazgos `HIGH` y `CRITICAL`, pero no bloquea la demostración.

Secrets requeridos:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
AWS_REGION
```

En AWS Academy, las credenciales son temporales. Deben actualizarse al reiniciar el laboratorio.

## Infraestructura ECS Fargate

La carpeta `aws/` crea o reutiliza:

- VPC y dos subredes públicas.
- Repositorios ECR.
- Security Groups.
- Roles IAM de ejecución y tarea.
- Log Groups de CloudWatch.
- Cluster ECS.
- Namespace privado `innovatech.local` para Service Connect.
- Application Load Balancer y reglas por ruta.
- Task definitions y servicios ECS.
- Autoscaling opcional para frontend y backends.

Arquitectura de acceso:

```text
Internet
   │
   ▼
ALB público :80
   ├── /api/v1/ventas*     → back-ventas-service :8080
   ├── /api/v1/despachos*  → back-despachos-service :8081
   └── /*                   → frontend-service :8080

backends ── Service Connect `mysql:3306` ── mysql-service
```

### Configuración

```bash
cp aws/.env.example aws/.env
```

Completa `aws/.env`, especialmente:

```text
DB_PASSWORD
MYSQL_ROOT_PASSWORD
```

No subas `aws/.env` al repositorio.

### Ejecución

```bash
bash aws/setup-infra.sh
```

Este es el comando recomendado para el primer despliegue. Requiere AWS CLI, Docker y `envsubst`. El flujo es continuo: crea ECR, construye y publica las tres imágenes `latest`, crea la infraestructura y los servicios ECS, espera que los cuatro servicios queden estables y ejecuta `10-verify.sh`. Así se evita depender de pipelines que intenten actualizar servicios ECS todavía inexistentes.

También puedes ejecutar los pasos individualmente:

```bash
bash aws/01-vpc.sh
bash aws/02-ecr.sh
bash aws/02-bootstrap-images.sh
bash aws/03-security-groups.sh
bash aws/04-iam-roles.sh
bash aws/05-cloudwatch.sh
bash aws/06-ecs-cluster.sh
bash aws/07-alb.sh
bash aws/08-ecs-services.sh
bash aws/09-autoscaling.sh
bash aws/10-verify.sh
```

Si se usan los pasos individuales, `02-bootstrap-images.sh` debe ejecutarse después de `02-ecr.sh` y antes de `08-ecs-services.sh`, porque los servicios ECS requieren que las imágenes `latest` ya existan en ECR. Después del despliegue inicial, los cambios normales se publican en la rama `deploy` y los tres workflows actualizan y comprueban cada servicio.

### Persistencia en ECS

El `mysql-service` incluido en ECS utiliza el almacenamiento efímero de la tarea Fargate. Sirve para demostraciones o laboratorios, pero no debe considerarse persistencia productiva. Para un entorno real se recomienda Amazon RDS/Aurora o una estrategia de almacenamiento persistente compatible.

## Despliegue manual heredado en EC2

Los archivos de `deploy/backend/` y `deploy/frontend/` se conservan como alternativa manual de la etapa anterior del proyecto. No son utilizados por los workflows ECS actuales.

## Seguridad y archivos excluidos

- `.env`, `aws/.env`, llaves privadas, certificados, builds y dependencias están excluidos por `.gitignore`.
- Los contenedores de aplicación se ejecutan con usuarios sin privilegios.
- MySQL no publica el puerto 3306 en el Compose local ni detrás del ALB.
- Las contraseñas de los archivos `.env.example` son marcadores y deben reemplazarse.
- Para producción, las credenciales de base de datos deberían migrarse a AWS Secrets Manager o SSM Parameter Store.

## Comandos de diagnóstico

```bash
docker compose ps
docker compose logs -f frontend
docker compose logs -f back-ventas
docker compose logs -f back-despachos
docker compose logs -f mysql
```

Validación local del código:

```bash
cd front_despacho
npm ci
npm run lint
npm run build

cd ../back-Ventas_SpringBoot/Springboot-API-REST
./mvnw test

cd ../../back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO
./mvnw test
```
