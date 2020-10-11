output "s3_state_bucket" {
  value = aws_s3_bucket.terraform_state.bucket
  description = "S3 state bucket"
}