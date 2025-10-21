output "frontend_s3_bucket_id" {
  value = aws_s3_bucket.frontend.id
}
output "assets_s3_bucket_id" {
  value = aws_s3_bucket.assets.id
}
output "ecr_repo_url" {
  value = aws_ecr_repository.app.repository_url
}
output "ecr_repo_name" {
  value = aws_ecr_repository.app.name
}
