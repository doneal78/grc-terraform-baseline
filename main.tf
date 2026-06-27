terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"
}

# IAM Account Password Policy
resource "aws_iam_account_password_policy" "grc_baseline" {
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
}

# S3 Bucket with encryption and versioning enabled
resource "aws_s3_bucket" "grc_compliant_bucket" {
  bucket = "oraclerecon-grc-compliant-bucket"

  tags = {
    Name        = "GRC Compliant Bucket"
    Environment = "Lab"
    Project     = "GRC Engineering Portfolio"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "grc_compliant_bucket_versioning" {
  bucket = aws_s3_bucket.grc_compliant_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "grc_compliant_bucket_encryption" {
  bucket = aws_s3_bucket.grc_compliant_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "grc_compliant_bucket_public_access" {
  bucket = aws_s3_bucket.grc_compliant_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# CloudTrail - Audit logging for all API calls
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = "oraclerecon-cloudtrail-logs"

  tags = {
    Name        = "CloudTrail Logs"
    Environment = "Lab"
    Project     = "GRC Engineering Portfolio"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket_public_access" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_bucket_encryption" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::oraclerecon-cloudtrail-logs"
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::oraclerecon-cloudtrail-logs/AWSLogs/868832438584/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "grc_trail" {
  name                          = "oraclerecon-grc-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  tags = {
    Name        = "GRC Audit Trail"
    Environment = "Lab"
    Project     = "GRC Engineering Portfolio"
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}