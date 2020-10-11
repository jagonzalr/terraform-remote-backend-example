resource "aws_s3_bucket" "example" {
  bucket = "${var.name}-example"
  acl = "private"
  force_destroy = true

  lifecycle_rule {
    id = "${var.name}-example-object-removal-rule"
    enabled = true
    expiration {
      days = 1
    }
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["HEAD", "GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["x-amz-server-side-encryption", "x-amz-request-id", "x-amz-id-2", "ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "example_access_block" {
  depends_on = [aws_s3_bucket.example]
  bucket = aws_s3_bucket.example.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}