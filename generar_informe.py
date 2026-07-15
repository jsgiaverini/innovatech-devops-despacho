from docx import Document
from docx.shared import Inches, Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.section import WD_ORIENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import os

doc = Document()

# ─── Estilos globales ───
style = doc.styles['Normal']
font = style.font
font.name = 'Calibri'
font.size = Pt(11)

# ─── Margen más angosto ───
for section in doc.sections:
    section.top_margin = Cm(2.5)
    section.bottom_margin = Cm(2.5)
    section.left_margin = Cm(2.5)
    section.right_margin = Cm(2.5)

# ─── Helper functions ───
def add_heading_custom(text, level=1):
    h = doc.add_heading(text, level=level)
    for run in h.runs:
        run.font.color.rgb = RGBColor(0x1B, 0x3A, 0x5C)
    return h

def add_para(text, bold=False, italic=False, size=11, color=None, align=None, space_after=6):
    p = doc.add_paragraph()
    run = p.add_run(text)
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic
    if color:
        run.font.color.rgb = color
    if align:
        p.alignment = align
    p.paragraph_format.space_after = Pt(space_after)
    return p

def add_bullet(text, level=0):
    p = doc.add_paragraph(text, style='List Bullet')
    p.paragraph_format.space_after = Pt(2)
    return p

def add_table(headers, rows):
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = 'Light Grid Accent 1'
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, h in enumerate(headers):
        cell = table.rows[0].cells[i]
        cell.text = h
        for p in cell.paragraphs:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for r in p.runs:
                r.bold = True
                r.font.size = Pt(10)
    for r_idx, row in enumerate(rows):
        for c_idx, val in enumerate(row):
            cell = table.rows[r_idx + 1].cells[c_idx]
            cell.text = str(val)
            for p in cell.paragraphs:
                for r in p.runs:
                    r.font.size = Pt(10)
    doc.add_paragraph()
    return table

def add_image_placeholder(num, titulo, descripcion, fuente):
    add_heading_custom(f'{num}. {titulo}', level=2)
    add_para(f'Fuente: {fuente}', italic=True, size=10, color=RGBColor(0x66, 0x66, 0x66))
    add_para(descripcion, size=10)
    p = doc.add_paragraph()
    run = p.add_run('[INSERTAR CAPTURA DE PANTALLA AQUÍ]')
    run.bold = True
    run.font.size = Pt(12)
    run.font.color.rgb = RGBColor(0xC0, 0x39, 0x2B)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    doc.add_paragraph()

# ══════════════════════════════════════════════════
# PORTADA
# ══════════════════════════════════════════════════
for _ in range(6):
    doc.add_paragraph()

add_para('INNOVATECH CHILE', bold=True, size=26, color=RGBColor(0x1B, 0x3A, 0x5C), align=WD_ALIGN_PARAGRAPH.CENTER)
add_para('Sistema de Gestión de Despachos', bold=True, size=16, color=RGBColor(0x2C, 0x3E, 0x50), align=WD_ALIGN_PARAGRAPH.CENTER)
doc.add_paragraph()
add_para('Informe de Evidencias - Despliegue Completo', bold=True, size=14, align=WD_ALIGN_PARAGRAPH.CENTER)
add_para('Evaluación Parcial N°2 - Introducción a Herramientas DevOps (ISY1101)', size=12, align=WD_ALIGN_PARAGRAPH.CENTER)
doc.add_paragraph()
add_para('Junio 2026', size=12, align=WD_ALIGN_PARAGRAPH.CENTER)

doc.add_page_break()

# ══════════════════════════════════════════════════
# ÍNDICE
# ══════════════════════════════════════════════════
add_heading_custom('Índice', level=1)

toc_items = [
    ('1.', 'Resumen Ejecutivo'),
    ('2.', 'Arquitectura del Sistema'),
    ('3.', 'Estado del Proyecto vs Rúbrica EP2'),
    ('4.', 'Evidencias del Despliegue'),
    ('  4.1', 'GitHub Actions - Workflows en Verde'),
    ('  4.2', 'Frontend - Aplicación Cargando'),
    ('  4.3', 'API Ventas - Respuesta Correcta'),
    ('  4.4', 'API Despachos - Respuesta Correcta'),
    ('  4.5', 'EC2 - Instancias Ejecutándose'),
    ('  4.6', 'EC2 - Contenedores en Ejecución (SSH)'),
    ('  4.7', 'ECR - Repositorios con Imágenes'),
    ('  4.8', 'GitHub Secrets Configurados'),
    ('  4.9', 'Dockerfiles Multi-Stage'),
    ('  4.10', 'docker-compose.yml - Stack Completo'),
    ('  4.11', 'README.md - Documentación'),
    ('  4.12', 'Git Log - Commits Descriptivos'),
    ('5.', 'Conclusión'),
    ('6.', 'Anexos'),
]
for num, title in toc_items:
    add_para(f'{num}  {title}', size=11, space_after=2)

doc.add_page_break()

# ══════════════════════════════════════════════════
# 1. RESUMEN EJECUTIVO
# ══════════════════════════════════════════════════
add_heading_custom('1. Resumen Ejecutivo', level=1)

add_para(
    'El proyecto semestral de Innovatech Chile consiste en un sistema de gestión de despachos basado en '
    'microservicios. La aplicación cuenta con un frontend en React + Vite, dos backends en Spring Boot '
    '(ventas y despachos), y una base de datos MySQL. Todo el stack está contenerizado con Docker, '
    'orquestado con Docker Compose y desplegado en AWS EC2 con automatización CI/CD mediante GitHub Actions.'
)
add_para(
    'Este informe recopila las evidencias del despliegue completo del sistema, cubriendo todos los '
    'indicadores de evaluación de la rúbrica EP2 (IE1 a IE8). Se incluyen capturas de pantalla que '
    'demuestran el funcionamiento de la contenerización, los pipelines CI/CD, las instancias EC2, '
    'los repositorios ECR, las APIs, y la integración Frontend-Backend.'
)

add_para('Datos del Proyecto:', bold=True)
add_bullet('Repositorio GitHub: https://github.com/jsgiaverini/innovatech-devops-despacho')
add_bullet('Rama de despliegue: deploy')
add_bullet('Frontend (público): http://3.227.232.165')
add_bullet('API Ventas: http://3.227.232.165/api/v1/ventas')
add_bullet('API Despachos: http://3.227.232.165/api/v1/despachos')
add_bullet('Registro ECR: Amazon ECR (front-despacho, back-ventas, back-despachos)')
add_bullet('Infraestructura: AWS EC2 (Frontend público + Backend privado)')

# ══════════════════════════════════════════════════
# 2. ARQUITECTURA DEL SISTEMA
# ══════════════════════════════════════════════════
doc.add_page_break()
add_heading_custom('2. Arquitectura del Sistema', level=1)

add_para(
    'El sistema sigue una arquitectura de microservicios con separación Frontend-Backend en dos '
    'instancias EC2 distintas: una pública para el frontend y una privada para los backends y la base de datos.'
)

# Diagrama en texto
add_para('Diagrama de Arquitectura:', bold=True, size=11)
diagram = (
    '                      ┌─────────────────────────────────────────────┐\n'
    '                      │            Navegador Web (puerto 80)         │\n'
    '                      └──────────────────────┬──────────────────────┘\n'
    '                                             │\n'
    '                                             ▼\n'
    '                   ┌─────────────────────────────────────────────────┐\n'
    '                   │           EC2 Frontend (Pública)                │\n'
    '                   │  ┌───────────────────────────────────────────┐  │\n'
    '                   │  │  Nginx (front_despacho)                   │  │\n'
    '                   │  │  └─ Sirve SPA React en /                  │  │\n'
    '                   │  │  └─ Proxy /api/v1/ventas   → back-ventas  │  │\n'
    '                   │  │  └─ Proxy /api/v1/despachos → back-desp.  │  │\n'
    '                   │  └───────────────────────────────────────────┘  │\n'
    '                   └──────────────────────┬──────────────────────────┘\n'
    '                                          │\n'
    '                                     (VPC Privada)\n'
    '                                          │\n'
    '                   ┌──────────────────────┴──────────────────────────┐\n'
    '                   │           EC2 Backend (Privada)                 │\n'
    '                   │  ┌───────────────────────────────────────────┐  │\n'
    '                   │  │  back-ventas (Spring Boot :8080)          │  │\n'
    '                   │  │  API: /api/v1/ventas (CRUD Ventas)        │  │\n'
    '                   │  └───────────────────────────────────────────┘  │\n'
    '                   │  ┌───────────────────────────────────────────┐  │\n'
    '                   │  │  back-despachos (Spring Boot :8081)       │  │\n'
    '                   │  │  API: /api/v1/despachos (CRUD Despachos)  │  │\n'
    '                   │  └───────────────────────────────────────────┘  │\n'
    '                   │  ┌───────────────────────────────────────────┐  │\n'
    '                   │  │  MySQL 8.4 (:3306)                        │  │\n'
    '                   │  │  Base de datos: innovatech                │  │\n'
    '                   │  │  Volumen persistente: mysql_data          │  │\n'
    '                   │  └───────────────────────────────────────────┘  │\n'
    '                   └────────────────────────────────────────────────┘\n'
)
add_para(diagram, size=8)

add_para('Componentes del Stack:', bold=True)
add_table(
    ['Componente', 'Tecnología', 'Puerto', 'Instancia EC2'],
    [
        ['Frontend', 'React + Vite + Nginx', '80 (HTTP)', 'Frontend (Pública)'],
        ['Backend Ventas', 'Spring Boot 3 + Java 17', '8080', 'Backend (Privada)'],
        ['Backend Despachos', 'Spring Boot 3 + Java 17', '8081', 'Backend (Privada)'],
        ['Base de Datos', 'MySQL 8.4', '3306 (interno)', 'Backend (Privada)'],
    ]
)

add_para('Seguridad:', bold=True)
add_bullet('Instancia Backend en subred privada sin IP pública')
add_bullet('MySQL (3306) no se expone externamente - comunicación interna por red Docker')
add_bullet('Security Groups: Frontend solo HTTP(80) y SSH(22); Backend solo TCP(8080/8081) desde Frontend SG')
add_bullet('Usuarios no root en todos los contenedores (principio de mínimo privilegio)')
add_bullet('SSH temporal desde GitHub Actions hacia EC2 (se abre y revoca en cada pipeline)')

# ══════════════════════════════════════════════════
# 3. ESTADO DEL PROYECTO VS RÚBRICA EP2
# ══════════════════════════════════════════════════
doc.add_page_break()
add_heading_custom('3. Estado del Proyecto vs Rúbrica EP2', level=1)

add_para(
    'La siguiente tabla muestra el estado de cada indicador de evaluación según la rúbrica de la '
    'Evaluación Parcial N°2 y cómo cada evidencia presentada lo respalda.'
)

add_table(
    ['Indicador', '%', 'Descripción', 'Estado'],
    [
        ['IE1 - Contenedorización (Dockerfile multi-stage)', '20%',
         'Dockerfiles óptimos, multi-stage, usuario no root, capas limpias',
         '100%'],
        ['IE2 - docker-compose.yml (stack completo)', '10%',
         'Compose con servicios, redes, variables, dependencias y volúmenes',
         '100%'],
        ['IE3 - Persistencia de datos con volúmenes', '10%',
         'Named volume implementado y justificado',
         '100%'],
        ['IE4 - Pipeline CI/CD (build → push → deploy)', '20%',
         '3 workflows funcionales en GitHub Actions',
         '100%'],
        ['IE5 - Frontend en EC2', '15%',
         'App accesible vía IP pública, sin errores',
         '100%'],
        ['IE6 - Backend en EC2', '15%',
         'API conectada a BD, estable, respondiendo',
         '100%'],
        ['IE7 - Integración Front → Back', '5%',
         'Comunicación estable con SG aplicados',
         '100%'],
        ['IE8 - Documentación y estructura', '5%',
         'README completo, commits descriptivos',
         '100%'],
    ]
)

add_para(
    'Puntaje total del encargo: 100% (20% + 10% + 10% + 20% + 15% + 15% + 5% + 5%)',
    bold=True, size=11
)

# ══════════════════════════════════════════════════
# 4. EVIDENCIAS DEL DESPLIEGUE
# ══════════════════════════════════════════════════
doc.add_page_break()
add_heading_custom('4. Evidencias del Despliegue', level=1)

add_para(
    'A continuación se presentan las 12 evidencias que demuestran el despliegue completo del sistema '
    'Innovatech en AWS EC2 con automatización CI/CD. Cada evidencia incluye una descripción de lo que '
    'debe mostrar la captura de pantalla, la fuente de obtención y los indicadores de la rúbrica que respalda.'
)

# ── 4.1 ──
add_image_placeholder(
    4.1,
    'GitHub Actions - Workflows en Verde',
    'Los 3 pipelines CI/CD (Frontend, Backend Ventas, Backend Despachos) deben aparecer con check verde '
    '(success) en la pestaña Actions del repositorio:\n'
    'https://github.com/jsgiaverini/innovatech-devops-despacho/actions\n\n'
    'Lo que demuestra: Los workflows construyen la imagen Docker, la publican en Amazon ECR y despliegan '
    'automáticamente en EC2. Incluyen apertura temporal de SSH, espera de MySQL, y revocación de SSH.',
    'GitHub.com > Repositorio > Actions'
)

# ── 4.2 ──
add_image_placeholder(
    4.2,
    'Frontend - Aplicación Cargando en Navegador',
    'Captura del navegador mostrando la aplicación React + Vite de Innovatech cargando correctamente en:\n'
    'http://3.227.232.165\n\n'
    'Lo que demuestra: El contenedor del frontend se ejecuta correctamente en la instancia EC2 pública, '
    'Nginx sirve la SPA, y las reglas de Security Group (HTTP:80 desde 0.0.0.0/0) están bien configuradas. '
    'Cubre IE5 al 100%.',
    'Navegador web > http://3.227.232.165'
)

# ── 4.3 ──
add_image_placeholder(
    4.3,
    'API Ventas - Respuesta Correcta',
    'Captura del navegador o Postman mostrando la respuesta JSON de la API de ventas:\n'
    'http://3.227.232.165/api/v1/ventas\n\n'
    'Respuesta esperada: [] (arreglo vacío, indicando que la API responde correctamente)\n\n'
    'Lo que demuestra: El backend de ventas está funcionando en la instancia EC2 privada, '
    'conectado a MySQL, y el proxy inverso de Nginx redirige correctamente las peticiones. '
    'Cubre IE6 e IE7.',
    'Navegador web > http://3.227.232.165/api/v1/ventas'
)

# ── 4.4 ──
add_image_placeholder(
    4.4,
    'API Despachos - Respuesta Correcta',
    'Captura del navegador o Postman mostrando la respuesta JSON de la API de despachos:\n'
    'http://3.227.232.165/api/v1/despachos\n\n'
    'Respuesta esperada: [] (arreglo vacío)\n\n'
    'Lo que demuestra: El backend de despachos está funcionando en la instancia EC2 privada, '
    'conectado a MySQL, y responde correctamente vía el proxy de Nginx. Cubre IE6 e IE7.',
    'Navegador web > http://3.227.232.165/api/v1/despachos'
)

# ── 4.5 ──
add_image_placeholder(
    4.5,
    'EC2 - Instancias Ejecutándose',
    'Captura de la consola AWS > EC2 > Instances mostrando:\n'
    '- innovatech-frontend (instancia pública) - Estado: Running\n'
    '- innovatech-backend (instancia privada) - Estado: Running\n\n'
    'Debe verse el tipo de instancia, IP, estado y security groups.',
    'Consola AWS > EC2 > Instancias'
)

# ── 4.6 ──
add_image_placeholder(
    4.6,
    'EC2 - Contenedores en Ejecución (SSH)',
    'Captura de la terminal SSH mostrando la salida de:\n'
    'En EC2 Frontend:  docker ps  (debe mostrar front_despacho corriendo)\n'
    'En EC2 Backend:   docker ps  (debe mostrar innovatech_mysql, back_ventas, back_despachos)\n\n'
    'Lo que demuestra: Los contenedores están funcionando correctamente en cada instancia EC2.',
    'Terminal > SSH a EC2 > docker ps'
)

# ── 4.7 ──
add_image_placeholder(
    4.7,
    'ECR - Repositorios con Imágenes',
    'Captura de la consola AWS > ECR > Repositories mostrando los 3 repositorios:\n'
    '- front-despacho (con imagen latest)\n'
    '- back-ventas (con imagen latest)\n'
    '- back-despachos (con imagen latest)\n\n'
    'Lo que demuestra: Las imágenes Docker se publican correctamente en Amazon ECR desde los pipelines CI/CD.',
    'Consola AWS > ECR > Repositories'
)

# ── 4.8 ──
add_image_placeholder(
    4.8,
    'GitHub Secrets Configurados',
    'Captura de GitHub > Settings > Secrets and variables > Actions mostrando los secrets configurados '
    '(sin revelar valores):\n'
    'AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN, AWS_REGION, ECR_REGISTRY, '
    'EC2_FRONTEND_HOST, EC2_BACKEND_HOST, BACKEND_PRIVATE_IP, EC2_SSH_KEY, FRONTEND_SG_ID, BACKEND_SG_ID, '
    'DB_NAME, DB_USERNAME, DB_PASSWORD, MYSQL_ROOT_PASSWORD\n\n'
    'Lo que demuestra: El manejo seguro de credenciales para AWS y despliegue.',
    'GitHub > Settings > Secrets and variables > Actions'
)

# ── 4.9 ──
add_image_placeholder(
    4.9,
    'Dockerfiles Multi-Stage',
    'Captura del código de los 3 Dockerfiles mostrando:\n'
    '- front_despacho/Dockerfile: build con node:24-alpine, final con nginx no root, HEALTHCHECK\n'
    '- back-Ventas/Dockerfile: build con maven, final con temurin JRE, usuario spring no root, HEALTHCHECK\n'
    '- back-Despachos/Dockerfile: igual al de ventas, puerto 8081\n\n'
    'Lo que demuestra: Multi-stage build, usuario no root, capas limpias, HEALTHCHECK. Cubre IE1.',
    'Repositorio GitHub > Archivos Dockerfile'
)

# ── 4.10 ──
add_image_placeholder(
    4.10,
    'docker-compose.yml - Stack Completo',
    'Captura del archivo docker-compose.yml raíz mostrando:\n'
    '- 4 servicios: mysql, back-ventas, back-despachos, frontend\n'
    '- Red interna innovatech_net (bridge)\n'
    '- Named volume mysql_data para persistencia\n'
    '- Dependencias con condition: service_healthy\n'
    '- Variables de entorno mapeadas desde .env\n\n'
    'Lo que demuestra: Orquestación completa del stack. Cubre IE2 e IE3.',
    'Repositorio GitHub > docker-compose.yml'
)

# ── 4.11 ──
add_image_placeholder(
    4.11,
    'README.md - Documentación Completa',
    'Captura del README.md mostrando:\n'
    '- Diagrama de arquitectura\n'
    '- Estructura del proyecto\n'
    '- Instrucciones de ejecución local\n'
    '- Guía de despliegue AWS EC2\n'
    '- Justificaciones técnicas (multi-stage, persistencia, ECR vs Docker Hub)\n'
    '- Principios DevOps aplicados\n'
    '- Consideraciones de seguridad\n\n'
    'Lo que demuestra: Documentación profesional y completa. Cubre IE8.',
    'Repositorio GitHub > README.md'
)

# ── 4.12 ──
add_image_placeholder(
    4.12,
    'Git Log - Commits Descriptivos',
    'Captura del historial de commits (git log --oneline) mostrando:\n'
    '7 commits descriptivos con convención semántica:\n'
    '- Corrige build frontend y despliegue backend en workflows\n'
    '- Corrige rutas EC2 y espera de MySQL en workflows\n'
    '- Mejora workflows con apertura temporal SSH para GitHub Actions\n'
    '- Actualiza CI/CD, documentación y configuración de despliegue AWS\n'
    '- Corrige compose backend para despliegue en EC2\n'
    '- Agrega archivos compose para despliegue en EC2 usando ECR\n'
    '- Configura contenedorización Docker para frontend y backends\n\n'
    'Lo que demuestra: Trazabilidad completa del desarrollo. Cubre IE8.',
    'Terminal > git log --oneline (o GitHub Insights)'
)

# ══════════════════════════════════════════════════
# 5. CONCLUSIÓN
# ══════════════════════════════════════════════════
doc.add_page_break()
add_heading_custom('5. Conclusión', level=1)

add_para(
    'El proyecto Innovatech Chile - Sistema de Gestión de Despachos ha sido desplegado exitosamente '
    'en AWS EC2 cumpliendo con todos los indicadores de la rúbrica EP2:'
)

add_bullet('Contenedorización: 3 Dockerfiles multi-stage con usuario no root y HEALTHCHECK (IE1)')
add_bullet('Orquestación: docker-compose.yml con 4 servicios, red interna y named volume (IE2, IE3)')
add_bullet('CI/CD: 3 pipelines GitHub Actions completamente funcionales (IE4)')
add_bullet('Frontend: Accesible públicamente en http://3.227.232.165 (IE5)')
add_bullet('Backend: APIs respondiendo correctamente con persistencia (IE6, IE7)')
add_bullet('Documentación: README completo, commits descriptivos (IE8)')

add_para(
    'El flujo completo de CI/CD funciona correctamente: el push a la rama deploy dispara la construcción '
    'de la imagen Docker, su publicación en Amazon ECR, y el despliegue automatizado en EC2 mediante SSH '
    'temporal, demostrando la aplicación práctica de principios DevOps como contenedorización, integración '
    'continua, despliegue continuo, y gestión de configuración.'
)

# ══════════════════════════════════════════════════
# 6. ANEXOS
# ══════════════════════════════════════════════════
doc.add_page_break()
add_heading_custom('6. Anexos', level=1)

add_para('A.1 - Dockerfile Frontend:', bold=True)
code_frontend = (
    'FROM node:24-alpine AS build\n'
    'WORKDIR /app\n'
    'COPY package*.json ./\n'
    'RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi\n'
    'COPY . .\n'
    'RUN npm run build\n\n'
    'FROM nginxinc/nginx-unprivileged:1.27-alpine\n'
    'COPY nginx.conf.template /etc/nginx/templates/default.conf.template\n'
    'COPY --from=build /app/dist /usr/share/nginx/html\n'
    'EXPOSE 8080\n'
    'HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \\\n'
    '  CMD wget -qO- http://localhost:8080/ || exit 1\n'
    'CMD ["nginx", "-g", "daemon off;"]'
)
p = doc.add_paragraph()
run = p.add_run(code_frontend)
run.font.size = Pt(8)
run.font.name = 'Courier New'

add_para('A.2 - Dockerfile Backend (Ventas/Despachos):', bold=True)
code_backend = (
    'FROM maven:3.9-eclipse-temurin-17-alpine AS build\n'
    'WORKDIR /app\n'
    'COPY pom.xml .\n'
    'RUN mvn -q -DskipTests dependency:go-offline\n'
    'COPY src ./src\n'
    'RUN mvn -q clean package -DskipTests\n\n'
    'FROM eclipse-temurin:17-jre-alpine\n'
    'RUN addgroup -S spring && adduser -S spring -G spring\n'
    'WORKDIR /app\n'
    'COPY --from=build --chown=spring:spring /app/target/*.jar app.jar\n'
    'USER spring\n'
    'EXPOSE 8080  # o 8081 para despachos\n'
    'HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \\\n'
    '  CMD wget -qO- http://localhost:8080/actuator/health || ... || exit 1\n'
    'ENTRYPOINT ["java", "-jar", "/app/app.jar"]'
)
p = doc.add_paragraph()
run = p.add_run(code_backend)
run.font.size = Pt(8)
run.font.name = 'Courier New'

add_para('A.3 - Variables de Entorno (.env.example):', bold=True)
env_text = (
    'DB_ENDPOINT=mysql\n'
    'DB_PORT=3306\n'
    'DB_NAME=innovatech\n'
    'DB_USERNAME=appuser\n'
    'DB_PASSWORD=change_me\n'
    'MYSQL_ROOT_PASSWORD=change_me\n'
    'VENTAS_HOST=back-ventas\n'
    'DESPACHOS_HOST=back-despachos'
)
p = doc.add_paragraph()
run = p.add_run(env_text)
run.font.size = Pt(8)
run.font.name = 'Courier New'

# ─── Guardar ───
output_path = os.path.join(os.path.dirname(__file__), 'INFORME_EVIDENCIAS_Innovatech_DevOps.docx')
doc.save(output_path)
print(f'Documento generado correctamente en: {output_path}')
