# =================================================================================
# Variables para el Entorno de Desarrollo (DEV)
# =================================================================================

environment = "dev"

# Configuración reducida para ahorrar costos en dev
db_instance_class     = "db.t3.micro"
db_allocated_storage  = 20
autoscale_min_tasks   = 1
autoscale_max_tasks   = 2

# Reemplaza con tus datos de GitHub
github_owner      = "your-github-username"
github_repo_infra = "ares-infra"
github_repo_app   = "ares-app"
github_branch     = "develop"
