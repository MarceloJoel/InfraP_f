# modules/storage/variables.tf

variable "project_name" {
  description = "Nombre del proyecto (ej. 'ares')"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, stage, prod)"
  type        = string
}

variable "account_id" {
  description = "ID de la cuenta de AWS"
  type        = string
}

variable "tags" {
  description = "Mapa de etiquetas comunes para aplicar a todos los recursos"
  type        = map(string)
  default     = {}
}

