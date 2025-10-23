# modules/security/outputs.tf
# Expone los IDs y ARNs de los recursos de seguridad

# --- Security Group IDs ---

output "alb_sg_id" {
  description = "ID del Security Group para el ALB"
  value       = aws_security_group.alb_sg.id
}

output "ecs_web_api_sg_id" {
  description = "ID del Security Group para el servicio ECS Web API"
  value       = aws_security_group.ecs_web_api_sg.id
}

output "ecs_worker_sg_id" {
  description = "ID del Security Group para el servicio ECS Worker"
  value       = aws_security_group.ecs_worker_sg.id
}

output "db_sg_id" {
  description = "ID del Security Group para la base de datos RDS"
  value       = aws_security_group.db_sg.id
}

# --- IAM Role ARNs ---

output "ecs_execution_role_arn" {
  description = "ARN del Rol de Ejecución de Tareas de ECS (común)"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_web_api_task_role_arn" {
  description = "ARN del Rol de Tarea de ECS para la Web API"
  value       = aws_iam_role.ecs_web_api_task_role.arn
}

output "ecs_worker_task_role_arn" {
  description = "ARN del Rol de Tarea de ECS para el Worker"
  value       = aws_iam_role.ecs_worker_task_role.arn
}

