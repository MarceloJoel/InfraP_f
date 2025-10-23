# Variables para el entorno de PRODUCCIÓN (prod)

environment = "prod"

# --- Base de Datos ---
db_instance_class      = "db.t3.small" # Instancia más robusta para producción
db_allocated_storage   = 100           # Más almacenamiento para producción

# --- CI/CD y GitHub ---
# REEMPLAZA ESTOS VALORES con los tuyos
# -------------------------------------------------------------------------------
github_owner            = "tu-usuario-de-github"
github_repo_infra       = "tu-repo-de-infraestructura"
github_repo_app         = "tu-repo-de-aplicacion"
codestar_connection_arn = "arn:aws:codestar-connections:us-east-1:123456789012:connection/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

