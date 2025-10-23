# modules/database/variables.tf

variable "project_name" {
  description = "Nombre del proyecto (ej. 'ares')"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, stage, prod)"
  type        = string
}

variable "db_instance_class" {
  description = "Tipo de instancia para la BD RDS"
  type        = string
}

variable "db_allocated_storage" {
  description = "Almacenamiento en GB para la BD RDS"
  type        = number
}

variable "db_name" {
  description = "Nombre de la base de datos a crear en RDS"
  type        = string
}

variable "db_username" {
  description = "Usuario administrador de la BD RDS"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Nombre del grupo de subredes de BD creado en el módulo 'network'"
  type        = string
}

variable "db_security_group_ids" {
  description = "Lista de IDs de Security Groups para la BD"
  type        = list(string)
}

variable "tags" {
  description = "Mapa de etiquetas comunes para aplicar a todos los recursos"
  type        = map(string)
  default     = {}
}

