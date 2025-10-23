# modules/security/variables.tf

variable "project_name" {
  description = "Nombre del proyecto (ej. 'ares')"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "El ID de la VPC donde se crearán los SGs"
  type        = string
}

variable "tags" {
  description = "Mapa de etiquetas comunes para aplicar a todos los recursos"
  type        = map(string)
  default     = {}
}

