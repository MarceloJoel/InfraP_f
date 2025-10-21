output "vpc_id" {
  value = aws_vpc.main.id
}
output "public_subnets_ids" {
  value = aws_subnet.public.*.id
}
output "private_subnets_ids" {
  value = aws_subnet.private.*.id
}
output "db_subnets_ids" {
  value = aws_subnet.database.*.id
}
