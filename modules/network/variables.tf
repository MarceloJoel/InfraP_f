# modules/network/variables.tf

variable "project_name" {
  description = "Nombre del proyecto (ej. 'ares')"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, stage, prod)."
  type        = string
}

variable "tags" {
  description = "Etiquetas comunes para aplicar a todos los recursos."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "Rango CIDR para la VPC"
  type        = string
}

variable "public_sn_cidrs" {
  description = "Rangos CIDR para las subredes públicas (debe tener 2)"
  type        = list(string)
}

variable "private_sn_cidrs" {
  description = "Rangos CIDR para las subredes privadas (debe tener 2)"
  type        = list(string)
}

variable "database_sn_cidrs" {
  description = "Rangos CIDR para las subredes de base de datos (debe tener 2)"
  type        = list(string)
}

