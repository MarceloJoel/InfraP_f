# Variables para el entorno de DESARROLLO (dev)

environment = "dev"

# --- Base de Datos ---
db_instance_class      = "db.t3.micro" # La instancia más pequeña para desarrollo
db_allocated_storage   = 20            # Mínimo de almacenamiento

# --- CI/CD y GitHub ---
# REEMPLAZA ESTOS VALORES con los tuyos
# -------------------------------------------------------------------------------
github_owner            = "tu-usuario-de-github"
github_repo_infra       = "tu-repo-de-infraestructura"
github_repo_app         = "tu-repo-de-aplicacion"
codestar_connection_arn = "arn:aws:codestar-connections:us-east-1:123456789012:connection/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

