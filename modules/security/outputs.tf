output "alb_sg_id" { value = aws_security_group.alb_sg.id }
output "ecs_sg_id" { value = aws_security_group.ecs_sg.id }
output "db_sg_id" { value = aws_security_group.db_sg.id }
output "ecs_task_role_arn" { value = aws_iam_role.ecs_task_role.arn }
output "ecs_execution_role_arn" { value = aws_iam_role.ecs_execution_role.arn }
