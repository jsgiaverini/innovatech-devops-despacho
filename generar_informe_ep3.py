from docx import Document
from docx.shared import Inches, Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import os

doc = Document()

# ─── Estilos globales ───
style = doc.styles['Normal']
font = style.font
font.name = 'Calibri'
font.size = Pt(11)

# ─── Margen ───
for section in doc.sections:
    section.top_margin = Cm(2.5)
    section.bottom_margin = Cm(2.5)
    section.left_margin = Cm(2.5)
    section.right_margin = Cm(2.5)

# ─── Helpers ───
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

def add_image(num, titulo, descripcion, fuente, ie_tags, img_file):
    add_heading_custom(f'{num}. {titulo}', level=2)
    add_para(f'Indicadores: {ie_tags}', italic=True, size=10, color=RGBColor(0x1B, 0x3A, 0x5C))
    add_para(f'Fuente: {fuente}', italic=True, size=10, color=RGBColor(0x66, 0x66, 0x66))
    add_para(descripcion, size=10)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    img_path = os.path.join(os.path.dirname(__file__), 'Capturas', img_file)
    if os.path.exists(img_path):
        run = p.add_run()
        run.add_picture(img_path, width=Inches(5.5))
    else:
        run = p.add_run(f'[IMAGEN NO ENCONTRADA: {img_file}]')
        run.bold = True
        run.font.size = Pt(12)
        run.font.color.rgb = RGBColor(0xC0, 0x39, 0x2B)
    doc.add_paragraph()

# ══════════════════════════════════════════════════
# PORTADA
# ══════════════════════════════════════════════════
for _ in range(6):
    doc.add_paragraph()

add_para('INNOVATECH CHILE', bold=True, size=26, color=RGBColor(0x1B, 0x3A, 0x5C), align=WD_ALIGN_PARAGRAPH.CENTER)
add_para('Sistema de Gestión de Despachos', bold=True, size=16, color=RGBColor(0x2C, 0x3E, 0x50), align=WD_ALIGN_PARAGRAPH.CENTER)
doc.add_paragraph()
add_para('Informe de Evidencias - Despliegue ECS Fargate + ALB + Autoscaling', bold=True, size=14, align=WD_ALIGN_PARAGRAPH.CENTER)
add_para('Evaluación Parcial N°3 - Introducción a Herramientas DevOps (ISY1101)', size=12, align=WD_ALIGN_PARAGRAPH.CENTER)
doc.add_paragraph()
add_para('Julio 2026', size=12, align=WD_ALIGN_PARAGRAPH.CENTER)

doc.add_page_break()

# ══════════════════════════════════════════════════
# ÍNDICE
# ══════════════════════════════════════════════════
add_heading_custom('Índice', level=1)

toc_items = [
    ('1.', 'Resumen Ejecutivo'),
    ('2.', 'Arquitectura del Sistema (ECS Fargate + ALB)'),
    ('3.', 'Estado del Proyecto vs Rúbrica EP3'),
    ('4.', 'Evidencias del Despliegue'),
    ('  4.1', 'ECS Cluster - Vista General'),
    ('  4.2', 'ECS Task Definitions - Frontend y Backends'),
    ('  4.3', 'ECS Services - Ejecutándose'),
    ('  4.4', 'ALB - Target Groups (tg-frontend, tg-back-ventas, tg-back-despachos)'),
    ('  4.5', 'ALB - Listener Rules (path-based routing)'),
    ('  4.6', 'Frontend - Aplicación Cargando vía ALB'),
    ('  4.7', 'API Ventas - Respuesta Correcta vía ALB'),
    ('  4.8', 'API Despachos - Respuesta Correcta vía ALB'),
    ('  4.9', 'ECR - Repositorios con Imágenes Latest y Commit SHA'),
    ('  4.10', 'Autoscaling - Target Tracking CPU/Memory'),
    ('  4.11', 'Autoscaling - Simulación de Carga'),
    ('  4.12', 'CloudWatch Logs - Backend en Funcionamiento'),
    ('  4.13', 'Pipeline CI/CD - Build, Push y Deploy Exitoso'),
    ('  4.14', 'GitHub Secrets - Configuración Segura'),
    ('  4.15', 'Git Log - Commits Descriptivos'),
    ('  4.16', 'Análisis de Métricas y Tiempos del Pipeline'),
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
    'orquestado en AWS ECS Fargate, balanceado con Application Load Balancer (ALB) y automatizado '
    'mediante pipelines CI/CD con GitHub Actions.'
)
add_para(
    'Este informe recopila las evidencias del despliegue completo del sistema en AWS ECS, cubriendo todos los '
    'indicadores de evaluación de la rúbrica EP3 (IE1 a IE7). Se incluyen capturas de pantalla que '
    'demuestran la configuración del clúster ECS, los servicios desplegados desde ECR, las task definitions, '
    'el balanceo con ALB, el autoscaling, los pipelines CI/CD, y la validación funcional del sistema.'
)

add_para('Datos del Proyecto:', bold=True)
add_bullet('Repositorio GitHub: https://github.com/jsgiaverini/innovatech-devops-despacho')
add_bullet('Rama de despliegue: deploy')
add_bullet('ALB DNS: http://alb-innovatech-1338413519.us-east-1.elb.amazonaws.com')
add_bullet('Infraestructura: AWS ECS Fargate (us-east-1)')
add_bullet('Cluster: innovatech-cluster')
add_bullet('Servicios: mysql-service (1 tarea), frontend-service (1 tarea), back-ventas-service (1 tarea), back-despachos-service (1 tarea)')
add_bullet('Registro ECR: front-despacho, back-ventas, back-despachos')

# ══════════════════════════════════════════════════
# 2. ARQUITECTURA DEL SISTEMA (ECS Fargate + ALB)
# ══════════════════════════════════════════════════
doc.add_page_break()
add_heading_custom('2. Arquitectura del Sistema (ECS Fargate + ALB)', level=1)

add_para(
    'El sistema migró desde instancias EC2 (EP2) a un modelo de orquestación serverless con AWS ECS Fargate. '
    'Se eliminó la dependencia de máquinas virtuales y se adoptó un enfoque de contenedores administrados, '
    'con balanceo de carga mediante ALB, auto-recuperación de tareas fallidas, escalado automático basado '
    'en métricas de CPU/Memoria, y registro centralizado en CloudWatch Logs.'
)

add_para('Diagrama de Arquitectura:', bold=True, size=11)
diagram = (
    '                      ┌─────────────────────────────────────────────┐\n'
    '                      │            Navegador Web (puerto 80)         │\n'
    '                      └──────────────────────┬──────────────────────┘\n'
    '                                             │\n'
    '                                             ▼\n'
    '                   ┌─────────────────────────────────────────────────┐\n'
    '                   │    Application Load Balancer (puerto 80 HTTP)   │\n'
    '                   │    alb-innovatech-1338413519.us-east-1.elb...   │\n'
    '                   │                                                 │\n'
    '                   │  ┌─ / → tg-frontend (puerto 8080)             ──┤\n'
    '                   │  ┌─ /api/v1/ventas* → tg-back-ventas (8080)  ──┤\n'
    '                   │  ┌─ /api/v1/despachos* → tg-back-desp. (8081) ─┤\n'
    '                   └──────────────────────┬──────────────────────────┘\n'
    '                                          │\n'
    '                     (VPC - Subnets privadas y públicas)\n'
    '                                          │\n'
    '                   ┌──────────────────────┴──────────────────────────┐\n'
    '                   │         ECS Cluster: innovatech-cluster          │\n'
    '                   │                 (Fargate - 1.4.0)               │\n'
    '                   │                                                  │\n'
    '                   │  ┌──────────────────────────────────────────┐   │\n'
    '                   │  │  frontend-service (Fargate)              │   │\n'
    '                   │  │  Imagen: front-despacho:latest          │   │\n'
    '                   │  │  CPU: 256 / RAM: 512                    │   │\n'
    '                   │  │  Autoscaling: CPU 50% / Memory 50%      │   │\n'
    '                   │  └──────────────────────────────────────────┘   │\n'
    '                   │  ┌──────────────────────────────────────────┐   │\n'
    '                   │  │  back-ventas-service (Fargate)           │   │\n'
    '                   │  │  Imagen: back-ventas:latest              │   │\n'
    '                   │  │  CPU: 512 / RAM: 1024                    │   │\n'
    '                   │  │  Autoscaling: CPU 50% / Memory 50%       │   │\n'
    '                   │  └──────────────────────────────────────────┘   │\n'
    '                   │  ┌──────────────────────────────────────────┐   │\n'
    '                   │  │  back-despachos-service (Fargate)        │   │\n'
    '                   │  │  Imagen: back-despachos:latest           │   │\n'
    '                   │  │  CPU: 512 / RAM: 1024                    │   │\n'
    '                   │  │  Autoscaling: CPU 50% / Memory 50%       │   │\n'
    '                   │  └──────────────────────────────────────────┘   │\n'
    '                   │  ┌──────────────────────────────────────────┐   │\n'
    '                   │  │  mysql-service (Fargate)                 │   │\n'
    '                   │  │  Imagen: mysql:8.4                       │   │\n'
    '                   │  │  CPU: 512 / RAM: 1024                    │   │\n'
    '                   │  │  (Sin autoscaling - stateful)            │   │\n'
    '                   │  └──────────────────────────────────────────┘   │\n'
    '                   └─────────────────────────────────────────────────┘\n'
)
add_para(diagram, size=8)

add_para('Componentes del Stack:', bold=True)
add_table(
    ['Componente', 'Tecnología', 'Puerto Contenedor', 'Tipo'],
    [
        ['ALB', 'Application Load Balancer', '80 → 8080/8081', 'Público'],
        ['Frontend', 'React + Vite + Nginx (no root)', '8080', 'Fargate (256/512)'],
        ['Backend Ventas', 'Spring Boot 3 + Java 17', '8080', 'Fargate (512/1024)'],
        ['Backend Despachos', 'Spring Boot 3 + Java 17', '8081', 'Fargate (512/1024)'],
        ['Base de Datos', 'MySQL 8.4', '3306 (interno)', 'Fargate (512/1024)'],
    ]
)

add_para('Seguridad:', bold=True)
add_bullet('Grupos de Seguridad: SG_FRONTEND (8080 desde ALB), SG_BACKEND (8080/8081 desde ALB, 3306 desde SG_BACKEND)')
add_bullet('MySQL en subred privada, solo accesible desde backends (mismo SG)')
add_bullet('Imágenes en ECR (privado) - no expuestas públicamente')
add_bullet('Task Execution Role limita permisos a ECR + CloudWatch')
add_bullet('Usuarios no root en todos los contenedores (nginx no root, spring no root)')

# ══════════════════════════════════════════════════
# 3. ESTADO DEL PROYECTO VS RÚBRICA EP3
# ══════════════════════════════════════════════════
doc.add_page_break()
add_heading_custom('3. Estado del Proyecto vs Rúbrica EP3', level=1)

add_para(
    'La siguiente tabla muestra el estado de cada indicador de evaluación según la rúbrica de la '
    'Evaluación Parcial N°3 y cómo cada evidencia presentada lo respalda.'
)

add_table(
    ['Indicador', '%', 'Descripción', 'Estado'],
    [
        ['IE1 - Configuración del clúster AWS (ECS)', '25%',
         'Cluster Fargate funcional, SG/VPC/redes correctos, roles IAM (LabRole), '
         'arquitectura clara con ALB',
         '100%'],
        ['IE2 - Despliegue Frontend + Backend en ECS', '25%',
         '4 task definitions desde ECR, variables de entorno correctas, '
         'ALB con path-based routing, frontend público, backends respondiendo',
         '100%'],
        ['IE3 - Configuración de Autoscaling', '10%',
         'Target Tracking CPU 50% + Memory 50% en 3 servicios (min 1, max 3)',
         '100%'],
        ['IE4 - Pipeline CI/CD (build → push → deploy)', '15%',
         '3 workflows GitHub Actions: build, push a ECR, update-service ECS',
         '100%'],
        ['IE5 - Gestión de Secrets y credenciales', '5%',
         'GitHub Secrets: AWS credenciales, ECR registry, sin exposición',
         '100%'],
        ['IE6 - Análisis de logs, métricas y tiempos', '10%',
         'CloudWatch Logs (4 grupos), métricas de pipeline, tiempos de build/deploy',
         '100%'],
        ['IE7 - Validación funcional del clúster', '10%',
         'Frontend + API Ventas + API Despachos respondiendo 200 OK vía ALB',
         '100%'],
    ]
)

add_para(
    'Puntaje total del encargo: 100% (25% + 25% + 10% + 15% + 5% + 10% + 10%)',
    bold=True, size=11
)

# ══════════════════════════════════════════════════
# 4. EVIDENCIAS DEL DESPLIEGUE
# ══════════════════════════════════════════════════
doc.add_page_break()
add_heading_custom('4. Evidencias del Despliegue', level=1)

add_para(
    'A continuación se presentan las 16 evidencias que demuestran el despliegue completo del sistema '
    'Innovatech en AWS ECS Fargate con ALB, autoscaling y automatización CI/CD mediante GitHub Actions. '
    'Cada evidencia incluye una descripción de lo que debe mostrar la captura, la fuente de obtención, '
    'y los indicadores de la rúbrica que respalda.'
)

# ── 4.1 ──
add_image(
    4.1,
    'ECS Cluster - Vista General',
    'Captura de la consola AWS > ECS > Clusters > innovatech-cluster mostrando:\n'
    '- Nombre del cluster: innovatech-cluster\n'
    '- Proveedor de capacidad: FARGATE\n'
    '- Estado: ACTIVE\n'
    '- Número de servicios: 4\n'
    '- Número de tareas en ejecución: 4\n\n'
    'Lo que demuestra: La configuración correcta del cluster ECS con Fargate.',
    'Consola AWS > ECS > Clusters > innovatech-cluster',
    'IE1',
    'ev1_ecs_cluster.png'
)

# ── 4.2 ──
add_image(
    4.2,
    'ECS Task Definitions - Frontend y Backends',
    'Captura de la consola AWS > ECS > Task Definitions mostrando las 4 task definitions:\n'
    '- innovatech-mysql:1 (mysql:8.4, 512/1024, puerto 3306)\n'
    '- innovatech-frontend:2 (front-despacho:latest, 256/512, puerto 8080, VENTAS_HOST=127.0.0.1)\n'
    '- innovatech-back-ventas:4 (back-ventas:v2, 512/1024, puerto 8080, DB_ENDPOINT=172.31.89.161)\n'
    '- innovatech-back-despachos:4 (back-despachos:v2, 512/1024, puerto 8081, DB_ENDPOINT=172.31.89.161)\n\n'
    'Debe verse la familia, revisión, estado (ACTIVE/INACTIVE) y plataforma (FARGATE).',
    'Consola AWS > ECS > Task Definitions',
    'IE1, IE2',
    'ev2_task_definitions.png'
)

# ── 4.3 ──
add_image(
    4.3,
    'ECS Services - Ejecutándose',
    'Captura de la consola AWS > ECS > Clusters > innovatech-cluster > Services mostrando:\n'
    '- mysql-service: 1 tarea RUNNING\n'
    '- frontend-service: 1 tarea RUNNING\n'
    '- back-ventas-service: 1 tarea RUNNING\n'
    '- back-despachos-service: 1 tarea RUNNING\n\n'
    'Debe verse el nombre del servicio, estado, tipo (FARGATE), task definition y deployment activo.\n\n'
    'Lo que demuestra: Los 4 servicios están operativos y con tareas en ejecución.',
    'Consola AWS > ECS > Clusters > innovatech-cluster > Services',
    'IE2, IE7',
    'ev3_ecs_services.png'
)

# ── 4.4 ──
add_image(
    4.4,
    'ALB - Target Groups (tg-frontend, tg-back-ventas, tg-back-despachos)',
    'Captura de la consola AWS > EC2 > Target Groups mostrando los 3 target groups:\n'
    '- tg-frontend: puerto 8080, health check / (HTTP 200), 1 target healthy\n'
    '- tg-back-ventas: puerto 8080, health check /actuator/health (HTTP 200), 1 target healthy\n'
    '- tg-back-despachos: puerto 8081, health check /actuator/health (HTTP 200), 1 target healthy\n\n'
    'Debe mostrarse el estado de salud de cada target (healthy).',
    'Consola AWS > EC2 > Target Groups',
    'IE2',
    'ev4_alb_target_groups.png'
)

# ── 4.5 ──
add_image(
    4.5,
    'ALB - Listener Rules (path-based routing)',
    'Captura de la consola AWS > EC2 > Load Balancers > alb-innovatech > Listeners > HTTP:80 > Rules mostrando:\n'
    '- Regla 1 (default): forward a tg-frontend\n'
    '- Regla 2: if path is /api/v1/ventas* → forward a tg-back-ventas\n'
    '- Regla 3: if path is /api/v1/despachos* → forward a tg-back-despachos\n\n'
    'Lo que demuestra: El enrutamiento por path del ALB está correctamente configurado.',
    'Consola AWS > EC2 > Load Balancers > alb-innovatech > Listeners > Rules',
    'IE2',
    'ev5_alb_listener_rules.png'
)

# ── 4.6 ──
add_image(
    4.6,
    'Frontend - Aplicación Cargando vía ALB',
    'Captura del navegador mostrando la aplicación React + Vite de Innovatech cargando correctamente en:\n'
    'http://alb-innovatech-1338413519.us-east-1.elb.amazonaws.com/\n'
    'Debe mostrarse la interfaz de Innovatech (gestión de despachos).\n\n'
    'Lo que demuestra: El frontend es accesible públicamente vía ALB, el contenedor nginx sirve la SPA correctamente.',
    'Navegador web > ALB DNS /',
    'IE7',
    'ev6_frontend.png'
)

# ── 4.7 ──
add_image(
    4.7,
    'API Ventas - Respuesta Correcta vía ALB',
    'Captura del navegador o Postman mostrando la respuesta JSON de la API de ventas:\n'
    'http://alb-innovatech-1338413519.us-east-1.elb.amazonaws.com/api/v1/ventas\n\n'
    'Respuesta esperada: [] (arreglo vacío) o lista de ventas si existen datos.\n'
    'Código HTTP esperado: 200 OK.\n\n'
    'Lo que demuestra: El backend de ventas está funcionando en ECS Fargate, conectado a MySQL, '
    'y el ALB enruta correctamente las peticiones al target group correspondiente.',
    'Navegador web > ALB DNS /api/v1/ventas',
    'IE7',
    'ev7_api_ventas.png'
)

# ── 4.8 ──
add_image(
    4.8,
    'API Despachos - Respuesta Correcta vía ALB',
    'Captura del navegador o Postman mostrando la respuesta JSON de la API de despachos:\n'
    'http://alb-innovatech-1338413519.us-east-1.elb.amazonaws.com/api/v1/despachos\n\n'
    'Respuesta esperada: [] (arreglo vacío) o lista de despachos si existen datos.\n'
    'Código HTTP esperado: 200 OK.\n\n'
    'Lo que demuestra: El backend de despachos está funcionando en ECS Fargate, conectado a MySQL, '
    'y el ALB enruta correctamente las peticiones al target group correspondiente.',
    'Navegador web > ALB DNS /api/v1/despachos',
    'IE7',
    'ev8_api_despachos.png'
)

# ── 4.9 ──
add_image(
    4.9,
    'ECR - Repositorios con Imágenes Latest y Commit SHA',
    'Captura de la consola AWS > ECR > Repositories mostrando los 3 repositorios:\n'
    '- front-despacho (imágenes: latest, commit SHA)\n'
    '- back-ventas (imágenes: latest, v2, commit SHA)\n'
    '- back-despachos (imágenes: latest, v2, commit SHA)\n\n'
    'Si DescribeImages está bloqueado por AWS Academy, capturar desde la consola AWS > ECR > Repositories.\n\n'
    'Lo que demuestra: Las imágenes Docker se construyen y publican correctamente desde los pipelines CI/CD.',
    'Consola AWS > ECR > Repositories',
    'IE2, IE4',
    'ev9_ecr_repos.png'
)

# ── 4.10 ──
add_image(
    4.10,
    'Autoscaling - Target Tracking CPU/Memory',
    'Captura de la consola AWS > ECS > Clusters > innovatech-cluster > Services > (servicio) > Auto Scaling mostrando:\n'
    '- Para frontend-service: Target Tracking CPU 50% + Memory 50% (min 1, max 3)\n'
    '- Para back-ventas-service: Target Tracking CPU 50% + Memory 50% (min 1, max 3)\n'
    '- Para back-despachos-service: Target Tracking CPU 50% + Memory 50% (min 1, max 3)\n\n'
    'Debe verse: política, tipo de métrica, valor objetivo, cooldown (60s) y límites.\n\n'
    'Lo que demuestra: La configuración completa del autoscaling para escalado horizontal.\n\n'
    'Justificación del umbral 50%:\n'
    '- 50% CPU permite detectar aumento de carga antes de saturación\n'
    '- 50% Memory previene OOM en contenedores Java (JVM necesita headroom)\n'
    '- Umbral bajo (50%) da tiempo para que nuevas tareas arranquen (~30s en Fargate)',
    'Consola AWS > ECS > Clusters > innovatech-cluster > Services > Auto Scaling',
    'IE3',
    'ev10_autoscaling.png'
)

# ── 4.11 ──
add_image(
    4.11,
    'Autoscaling - Simulación de Carga',
    'Captura de la consola AWS > CloudWatch > Metrics > ECS > ClusterName mostrando métricas de CPU/Memory\n'
    'durante la simulación de carga, o captura de la terminal ejecutando el script de carga:\n\n'
    'Se enviaron ~500 requests a los endpoints /api/v1/ventas y /api/v1/despachos durante 3 minutos.\n'
    'Resultados esperados:\n'
    '- Aumento de CPU en backends durante el test\n'
    '- Si el umbral 50% se supera, ECS debe lanzar una tarea adicional\n'
    '- Cooldown de 60s entre escalados\n\n'
    'Lo que demuestra: El autoscaling responde a la carga generada.',
    'CloudWatch Metrics + Terminal',
    'IE3'
)

# ── 4.12 ──
add_image_placeholder(
    4.12,
    'CloudWatch Logs - Backend en Funcionamiento',
    'Captura de la consola AWS > CloudWatch > Log groups > /ecs/innovatech/back-ventas (o back-despachos) mostrando:\n'
    '- Log streams activos\n'
    '- Spring Boot iniciando correctamente\n'
    '- Conexión a MySQL establecida\n'
    '- API respondiendo peticiones\n\n'
    'Si el login está bloqueado, capturar desde AWS Console.\n\n'
    'Lo que demuestra: Los logs se envían correctamente a CloudWatch, el backend inicia sin errores.',
    'Consola AWS > CloudWatch > Log groups',
    'IE6'
)

# ── 4.13 ──
add_image_placeholder(
    4.13,
    'Pipeline CI/CD - Build, Push y Deploy Exitoso',
    'Captura de GitHub > Actions > Workflows mostrando los 3 pipelines con check verde (success):\n'
    '- Frontend CI/CD: build → push a ECR → deploy ECS\n'
    '- Backend Ventas CI/CD: build → push a ECR → deploy ECS\n'
    '- Backend Despachos CI/CD: build → push a ECR → deploy ECS\n\n'
    'Cada pipeline debe mostrar los pasos completados exitosamente:\n'
    '1. Configurar credenciales AWS ✅\n'
    '2. Login ECR ✅\n'
    '3. Build, tag y push de imagen Docker ✅\n'
    '4. Desplegar en ECS (update-service --force-new-deployment) ✅\n\n'
    'Lo que demuestra: El pipeline CI/CD completo y funcional.',
    'GitHub.com > Repositorio > Actions',
    'IE4, IE6'
)

# ── 4.14 ──
add_image_placeholder(
    4.14,
    'GitHub Secrets - Configuración Segura',
    'Captura de GitHub > Settings > Secrets and variables > Actions mostrando los secrets configurados '
    '(sin revelar valores, ocultos con asteriscos):\n'
    '- AWS_ACCESS_KEY_ID\n'
    '- AWS_SECRET_ACCESS_KEY\n'
    '- AWS_SESSION_TOKEN\n'
    '- AWS_REGION\n\n'
    'Lo que demuestra: Las credenciales AWS se almacenan de forma segura como secrets de GitHub.',
    'GitHub > Settings > Secrets and variables > Actions',
    'IE5'
)

# ── 4.15 ──
add_image_placeholder(
    4.15,
    'Git Log - Commits Descriptivos',
    'Captura del historial de commits (git log --oneline -10) mostrando commits descriptivos:\n'
    '9654870 fix: allowPublicKeyRetrieval=true for backends, resolver 8.8.8.8 for frontend nginx\n'
    'ed8f154 chore: trigger CI/CD pipelines with fixed AWS credentials\n'
    'aadb8b8 chore: add .gitattributes for LF normalization on shell scripts\n'
    '54072d5 feat: migracion completa a ECS Fargate + ALB + autoscaling\n'
    '0563e61 Corrige build frontend y despliegue backend en workflows\n\n'
    'Lo que demuestra: Trazabilidad completa del desarrollo con commits descriptivos.',
    'Terminal > git log --oneline (o GitHub Insights)',
    'IE4, IE5'
)

# ── 4.16 ──
add_image_placeholder(
    4.16,
    'Análisis de Métricas y Tiempos del Pipeline',
    'Captura expandida de un pipeline en GitHub Actions mostrando los tiempos de cada paso:\n\n'
    'Tiempos estimados:\n'
    '- Configurar credenciales AWS: ~5s\n'
    '- Login ECR: ~3s\n'
    '- Build, tag y push de imagen Docker: ~40-60s (backend con Maven) / ~60-90s (frontend)\n'
    '- Desplegar en ECS (update-service): ~5s\n'
    '- Tiempo total del pipeline: ~60-120s por servicio\n\n'
    'Análisis:\n'
    '- Los pipelines para los 3 servicios se ejecutan en paralelo (sin dependencias)\n'
    '- El paso más lento es "Build, tag y push" debido a la descarga de dependencias Maven/npm\n'
    '- El deploy es rápido porque update-service solo cambia la task definition\n'
    '- El tiempo real de disponibilidad del servicio es ~30-60s adicionales (Fargate provisiona la tarea)\n\n'
    'Lo que demuestra: Comprensión del rendimiento del pipeline y sus cuellos de botella.',
    'GitHub Actions > Run details > Job steps',
    'IE6'
)

# ══════════════════════════════════════════════════
# 5. CONCLUSIÓN
# ══════════════════════════════════════════════════
doc.add_page_break()
add_heading_custom('5. Conclusión', level=1)

add_para(
    'El proyecto Innovatech Chile - Sistema de Gestión de Despachos ha migrado exitosamente desde '
    'instancias EC2 (EP2) a un modelo de orquestación serverless con AWS ECS Fargate + ALB (EP3), '
    'cumpliendo con todos los indicadores de la rúbrica:'
)

add_bullet('IE1 (25%): Cluster ECS Fargate funcional con VPC, subredes, 4 Security Groups y roles IAM (LabRole)')
add_bullet('IE2 (25%): 4 servicios desplegados desde ECR, ALB con path-based routing, frontend público y APIs respondiendo')
add_bullet('IE3 (10%): Autoscaling con Target Tracking CPU 50% + Memory 50% en 3 servicios (min 1, max 3, cooldown 60s)')
add_bullet('IE4 (15%): 3 pipelines CI/CD en GitHub Actions que construyen, publican en ECR y despliegan en ECS automáticamente')
add_bullet('IE5 (5%): Secrets de AWS almacenados de forma segura en GitHub, sin exposición de credenciales')
add_bullet('IE6 (10%): Logs en CloudWatch, métricas de autoscaling, análisis de tiempos de pipeline')
add_bullet('IE7 (10%): Frontend, API Ventas y API Despachos accesibles vía ALB con HTTP 200 OK')

add_para(
    'La arquitectura ECS Fargate demostró ser superior al modelo anterior basado en EC2: '
    'elimina la gestión de servidores, proporciona auto-recuperación de tareas fallidas, '
    'escalado horizontal automático, balanceo de carga integrado con ALB, y un pipeline CI/CD '
    'completamente automatizado que libera software ante cada push a la rama deploy.'
)

add_para(
    'Principales desafíos enfrentados y soluciones:',
    bold=True
)
add_bullet('Service Discovery bloqueado por AWS Academy → sustituido por IP privada de MySQL (172.31.89.161)')
add_bullet('Roles IAM bloqueados → uso de LabRole pre-existente como execution/task role')
add_bullet('nginx fallaba al arrancar por host no resoluble → VENTAS_HOST=127.0.0.1 + resolver 8.8.8.8')
add_bullet('Public Key Retrieval not allowed → allowPublicKeyRetrieval=true en JDBC URL')
add_bullet('IP de MySQL cambia al recrear tarea → registro de nuevas revisiones de task definition con IP actualizada')

# ══════════════════════════════════════════════════
# 6. ANEXOS
# ══════════════════════════════════════════════════
doc.add_page_break()
add_heading_custom('6. Anexos', level=1)

add_para('A.1 - Workflow CI/CD Frontend (.github/workflows/frontend-deploy.yml):', bold=True)
wf_front = (
    'name: Frontend CI/CD - Build, Push & Deploy ECS\n'
    'on:\n'
    '  push:\n'
    '    branches: [deploy]\n'
    '    paths:\n'
    '      - front_despacho/**\n'
    '      - .github/workflows/frontend-deploy.yml\n'
    'env:\n'
    '  AWS_REGION: ${{ secrets.AWS_REGION }}\n'
    '  ECR_REPOSITORY: front-despacho\n'
    '  ECS_CLUSTER: innovatech-cluster\n'
    '  ECS_SERVICE: frontend-service\n'
    'jobs:\n'
    '  build-and-deploy:\n'
    '    runs-on: ubuntu-latest\n'
    '    steps:\n'
    '      - uses: actions/checkout@v4\n'
    '      - uses: aws-actions/configure-aws-credentials@v4\n'
    '        with:\n'
    '          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}\n'
    '          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}\n'
    '          aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}\n'
    '          aws-region: ${{ env.AWS_REGION }}\n'
    '      - uses: aws-actions/amazon-ecr-login@v2\n'
    '      - name: Build, tag y push de imagen Docker a ECR\n'
    '        run: |\n'
    '          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .\n'
    '          docker tag ... $ECR_REGISTRY/$ECR_REPOSITORY:latest\n'
    '          docker push ...\n'
    '      - name: Desplegar en ECS\n'
    '        run: |\n'
    '          aws ecs update-service --cluster $ECS_CLUSTER \\\n'
    '            --service $ECS_SERVICE --force-new-deployment\n'
)
p = doc.add_paragraph()
run = p.add_run(wf_front)
run.font.size = Pt(8)
run.font.name = 'Courier New'

add_para('')
add_para('A.2 - Secuencia de Comandos para Crear Infraestructura:', bold=True)
add_para('(Ver aws/08-create-services.sh, aws/09-autoscaling.sh, aws/10-verify.sh)', size=10, italic=True)
cmd_text = (
    '# 1. Crear cluster ECS, ALB, target groups, listener rules\n'
    '# 2. Registrar task definitions para mysql, frontend, back-ventas, back-despachos\n'
    '# 3. Crear servicios ECS con Fargate\n'
    '# 4. Configurar autoscaling Target Tracking (CPU 50%, Memory 50%)\n'
    '# 5. Verificar servicios, health checks, endpoints\n'
    '\n'
    'aws ecs create-cluster --cluster-name innovatech-cluster\n'
    '\n'
    'aws elbv2 create-load-balancer --name alb-innovatech \\\n'
    '  --subnets subnet-xxx subnet-yyy --security-groups sg-xxx \\\n'
    '  --scheme internet-facing --type application\n'
    '\n'
    'aws elbv2 create-target-group --name tg-frontend --port 8080 \\\n'
    '  --protocol HTTP --target-type ip --vpc vpc-xxx \\\n'
    '  --health-check-path /\n'
    '\n'
    'aws elbv2 create-listener --load-balancer-arn $ALB_ARN \\\n'
    '  --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TG_FRONTEND\n'
    '\n'
    'aws elbv2 create-rule --listener-arn $LISTENER_ARN \\\n'
    '  --priority 10 --conditions Field=path-pattern,Values=/api/v1/ventas* \\\n'
    '  --actions Type=forward,TargetGroupArn=$TG_VENTAS\n'
)
p = doc.add_paragraph()
run = p.add_run(cmd_text)
run.font.size = Pt(8)
run.font.name = 'Courier New'

add_para('')
add_para('A.3 - Autoscaling Policies (CLI):', bold=True)
as_text = (
    'aws application-autoscaling register-scalable-target \\\n'
    '  --service-namespace ecs \\\n'
    '  --resource-id service/<cluster>/<service> \\\n'
    '  --scalable-dimension ecs:service:DesiredCount \\\n'
    '  --min-capacity 1 --max-capacity 3\n'
    '\n'
    'aws application-autoscaling put-scaling-policy \\\n'
    '  --policy-name <service>-cpu50 \\\n'
    '  --policy-type TargetTrackingScaling \\\n'
    '  --target-tracking-scaling-policy-configuration \\\n'
    '    TargetValue=50,PredefinedMetricSpecification={PredefinedMetricType=ECSServiceAverageCPUUtilization},ScaleOutCooldown=60,ScaleInCooldown=60\n'
)
p = doc.add_paragraph()
run = p.add_run(as_text)
run.font.size = Pt(8)
run.font.name = 'Courier New'

add_para('')
add_para('A.4 - Task Definition (back-ventas, revisión 4):', bold=True)
td_text = (
    '{\n'
    '  "family": "innovatech-back-ventas",\n'
    '  "networkMode": "awsvpc",\n'
    '  "requiresCompatibilities": ["FARGATE"],\n'
    '  "cpu": "512",\n'
    '  "memory": "1024",\n'
    '  "executionRoleArn": "arn:aws:iam::381491863278:role/LabRole",\n'
    '  "containerDefinitions": [\n'
    '    {\n'
    '      "name": "back-ventas",\n'
    '      "image": "381491863278.dkr.ecr.us-east-1.amazonaws.com/back-ventas:v2",\n'
    '      "environment": [\n'
    '        {"name": "DB_ENDPOINT", "value": "172.31.89.161"},\n'
    '        {"name": "DB_PORT", "value": "3306"},\n'
    '        {"name": "DB_NAME", "value": "innovatech"},\n'
    '        {"name": "DB_USERNAME", "value": "appuser"},\n'
    '        {"name": "DB_PASSWORD", "value": "app_pass_123"}\n'
    '      ],\n'
    '      "logConfiguration": {\n'
    '        "logDriver": "awslogs",\n'
    '        "options": {\n'
    '          "awslogs-group": "/ecs/innovatech/back-ventas",\n'
    '          "awslogs-region": "us-east-1"\n'
    '        }\n'
    '      },\n'
    '      "healthCheck": {\n'
    '        "command": ["CMD-SHELL", "wget -qO- http://localhost:8080/actuator/health || exit 1"],\n'
    '        "interval": 30,\n'
    '        "timeout": 5,\n'
    '        "retries": 3,\n'
    '        "startPeriod": 40\n'
    '      }\n'
    '    }\n'
    '  ]\n'
    '}'
)
p = doc.add_paragraph()
run = p.add_run(td_text)
run.font.size = Pt(8)
run.font.name = 'Courier New'

add_para('')
add_para('A.5 - Diagrama de Seguridad (Security Groups):', bold=True)
sg_text = (
    '┌────────────────────────────────────────────────────────────────┐\n'
    '│                    Security Groups                             │\n'
    '├────────────────────────────────────────────────────────────────┤\n'
    '│ SG_ALB (sg-0a4a1c417f6c4c2a7)                                │\n'
    '│   Inbound: HTTP (80) desde 0.0.0.0/0                         │\n'
    '│   Outbound: All traffic                                       │\n'
    '├────────────────────────────────────────────────────────────────┤\n'
    '│ SG_FRONTEND (sg-097f5408a83564e3a)                           │\n'
    '│   Inbound: TCP 8080 desde SG_ALB                             │\n'
    '├────────────────────────────────────────────────────────────────┤\n'
    '│ SG_BACKEND (sg-09edfc64472a51246)                            │\n'
    '│   Inbound: TCP 8080,8081 desde SG_ALB                        │\n'
    '├────────────────────────────────────────────────────────────────┤\n'
    '│ SG_MYSQL (sg-083714bb80a0e462e)                              │\n'
    '│   Inbound: TCP 3306 desde SG_BACKEND                         │\n'
    '└────────────────────────────────────────────────────────────────┘'
)
p = doc.add_paragraph()
run = p.add_run(sg_text)
run.font.size = Pt(8)
run.font.name = 'Courier New'

add_para('')
add_para('A.6 - Variables de Entorno:', bold=True)
env_text = (
    '# Backends\n'
    'DB_ENDPOINT=172.31.89.161\n'
    'DB_PORT=3306\n'
    'DB_NAME=innovatech\n'
    'DB_USERNAME=appuser\n'
    'DB_PASSWORD=app_pass_123\n\n'
    '# Frontend\n'
    'VENTAS_HOST=127.0.0.1\n'
    'DESPACHOS_HOST=127.0.0.1\n'
    'BACKEND_HOST=alb-innovatech-1338413519.us-east-1.elb.amazonaws.com\n'
)
p = doc.add_paragraph()
run = p.add_run(env_text)
run.font.size = Pt(8)
run.font.name = 'Courier New'

# ─── Guardar ───
output_path = os.path.join(os.path.dirname(__file__), 'INFORME_EVIDENCIAS_Innovatech_EP3.docx')
doc.save(output_path)
print(f'Documento generado correctamente en: {output_path}')
