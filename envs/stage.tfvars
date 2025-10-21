# =================================================================================
# Variables para el Entorno de Staging (STAGE)
# =================================================================================

environment = "stage"

# Configuración intermedia, más similar a producción
db_instance_class     = "db.t3.small"
db_allocated_storage  = 50
autoscale_min_tasks   = 2
autoscale_max_tasks   = 4

# Reemplaza con tus datos de GitHub
github_owner      = "your-github-username"
github_repo_infra = "ares-infra"
github_repo_app   = "ares-app"
github_branch     = "release"
