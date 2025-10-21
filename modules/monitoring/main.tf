# Módulo de Monitoreo: CloudWatch Log Group

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}-app-${var.environment}"
  retention_in_days = 30 # Ajustar según la política de retención

  tags = {
    Name        = "${var.project_name}-ecs-logs-${var.environment}"
    Environment = var.environment
  }
}
