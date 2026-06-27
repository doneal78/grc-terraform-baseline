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

# S3 Compliant Bucket
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

# CloudTrail Bucket
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

# AWS Config IAM Role
resource "aws_iam_role" "config_role" {
  name = "oraclerecon-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "AWS Config Role"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# AWS Config S3 Bucket
resource "aws_s3_bucket" "config_bucket" {
  bucket = "oraclerecon-config-logs"

  tags = {
    Name        = "AWS Config Logs"
    Environment = "Lab"
    Project     = "GRC Engineering Portfolio"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "config_bucket_public_access" {
  bucket = aws_s3_bucket.config_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket_encryption" {
  bucket = aws_s3_bucket.config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::oraclerecon-config-logs"
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::oraclerecon-config-logs/AWSLogs/868832438584/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# AWS Config Recorder
resource "aws_config_configuration_recorder" "grc_recorder" {
  name     = "oraclerecon-grc-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "grc_delivery" {
  name           = "oraclerecon-grc-delivery"
  s3_bucket_name = aws_s3_bucket.config_bucket.id

  depends_on = [
    aws_config_configuration_recorder.grc_recorder,
    aws_s3_bucket_policy.config_bucket_policy
  ]
}

resource "aws_config_configuration_recorder_status" "grc_recorder_status" {
  name       = aws_config_configuration_recorder.grc_recorder.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.grc_delivery]
}

# AWS Config Managed Rules
resource "aws_config_config_rule" "s3_encryption" {
  name = "s3-bucket-server-side-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.grc_recorder_status]
}

resource "aws_config_config_rule" "s3_public_access" {
  name = "s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.grc_recorder_status]
}

resource "aws_config_config_rule" "mfa_enabled" {
  name = "mfa-enabled-for-iam-console-access"

  source {
    owner             = "AWS"
    source_identifier = "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS"
  }

  depends_on = [aws_config_configuration_recorder_status.grc_recorder_status]
}

resource "aws_config_config_rule" "root_no_access_keys" {
  name = "iam-root-access-key-check"

  source {
    owner             = "AWS"
    source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK"
  }

  depends_on = [aws_config_configuration_recorder_status.grc_recorder_status]
}