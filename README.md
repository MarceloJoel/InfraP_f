## ⚙️DOCUMENTACIÓN

## 🧾PROYECTO:\
INFRAESTRUCTURA AWS CON TERRAFORM PARA SISTEMA DE RESERVAS DE MESAS.

## ⚙️DESCRIPCIÓN GENERAL:\
Este proyecto implementa la infraestructura completa de un sistema de reservas de mesas en AWS utilizando Terraform bajo el enfoque de Infraestructura como Código (IaC).

## 🧩 ARQUITECTURA GENERAL:\
- La arquitectura incluye:
- Red (VPC): Subredes públicas y privadas distribuidas en 2 Zonas de Disponibilidad.
- Servicio Web API (ECS Fargate): Un servicio principal de Spring Boot que atiende el tráfico web de la API, autoescalable y balanceado por un ALB.
- Servicio Asíncrono (SQS + ECS Worker): Una cola de SQS para manejar tareas pesadas (como envío de correos) y un servicio "worker" de ECS Fargate que procesa los mensajes de la cola.
- Frontend (S3 + CloudFront): Un bucket S3 para alojar el frontend estático (Angular) y una distribución de CloudFront (CDN) con AWS WAF para seguridad y rendimiento.
- Base de Datos (RDS): Una instancia de MySQL en modo Multi-AZ (Primario/Standby) para alta disponibilidad.
- CI/CD (CodePipeline): Dos pipelines separados para gestionar la infraestructura y el despliegue de aplicaciones.
- Seguridad: Grupos de seguridad con mínimo privilegio, roles de IAM y gestión de secretos con AWS Secrets Manager.

📜 ESTRUCTURA DE ARCHIVOS

.
├── modules/ \
│   ├── cicd/ \
│   ├── compute/ \
│   ├── database/ \
│   ├── network/ \
│   ├── security/ \
│   └── storage/ \
├── envs/ \
│   ├── dev.tfvars\
│   ├── stage.tfvars\
│   └── prod.tfvars\
├── buildspec/ \
│   ├── app_build.yml\
│   ├── app_deploy.yml\
│   └── infra_apply.yml\
├── main.tf\
├── variables.tf\
├── outputs.tf\
├── providers.tf\
└── README.md\

## 🚀 INSTRUCCIONES DE DESPLIEGUE\
REQUISITOS PREVIOS:\
- Cuenta AWS con permisos de administrador.
- AWS CLI configurado (aws configure).
- Terraform instalado (v1.5+).
- Dominio en Route 53: Necesitas tener una Zona Hospedada (Hosted Zone) pública en AWS Route 53 para el dominio que usarás (ej. midominio.com).
- Bucket S3 y Tabla DynamoDB: Creados manualmente en us-east-1 para el backend remoto de Terraform.
- Git para clonar el repositorio.

## 🚀 Pasos para el Despliegue

---

### 🧱 1. Configurar el Backend Remoto

Actualiza el archivo **`providers.tf`** con los nombres de tu **bucket S3** y tu **tabla de DynamoDB**.

```hcl
backend "s3" {
  bucket         = "tu-bucket-de-estado-tf"
  key            = "global/s3/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "tu-tabla-de-bloqueo-tf"
}
```
### ⚙️ 2. Configurar las Variables de Entorno

Edita el archivo envs/dev.tfvars y rellena los valores requeridos, especialmente:

domain_name → ej. "https://www.google.com/search?q=mi-proyecto.com"

hosted_zone_id → ID de tu zona en Route 53

github_owner → tu usuario u organización de GitHub

github_repo_infra → nombre del repo de Infraestructura (IaC)

github_repo_app → nombre del repo de Aplicación

codestar_connection_arn → ARN de la conexión creada en el paso 5 de requisitos

---
### 🧩 3. Inicializar Terraform

Ejecuta este comando en la carpeta raíz del proyecto.
Terraform descargará los providers y se conectará a tu backend remoto.
```
terraform init
```
---
### 🧮 4. Planificar el Despliegue (Entorno dev)

Revisa los cambios que Terraform va a aplicar antes de ejecutarlos.
```
terraform plan -var-file="envs/dev.tfvars"
```
---
### 🏗️ 5. Aplicar el Despliegue (Entorno dev)

Construye la infraestructura automáticamente.

```
terraform apply -var-file="envs/dev.tfvars" -auto-approve
```

---

### 💣 6. Destruir la Infraestructura (Entorno `dev`)

Si necesitas **eliminar todos los recursos creados** por Terraform en el entorno `dev`, ejecuta:

```bash
terraform destroy -var-file="envs/dev.tfvars" -auto-approve

