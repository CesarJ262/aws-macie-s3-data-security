# ==============================================================================
# PROVIDER & INITIAL CONFIGURATION
# ==============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # You can change this to your preferred AWS region
}

# Dynamically fetch the current AWS Account ID to avoid hardcoding sensitive data
data "aws_caller_identity" "current" {}

# ==============================================================================
# 1. AWS KMS: CUSTOMER MANAGED KEY & KEY POLICY
# ==============================================================================
resource "aws_kms_key" "macie_key" {
  description             = "KMS Managed Key for Amazon Macie compliance auditing"
  deletion_window_in_days = 7
  enable_key_rotation     = true # Security best practice recommended

  # Attaching the strict Key Policy that delegates decryption rights to the Macie Service-Linked Role
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Macie Service Role Access"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/macie.amazonaws.com/AWSServiceRoleForAmazonMacie"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# Creating a user-friendly alias to easily identify the key within the AWS Console
resource "aws_kms_alias" "macie_key_alias" {
  name          = "alias/macie-s3-key"
  target_key_id = aws_kms_key.macie_key.key_id
}

# ==============================================================================
# 2. AMAZON S3: HARDENED BUCKET (DATA VAULT)
# ==============================================================================
resource "aws_s3_bucket" "secure_vault" {
  bucket        = "aws-macie-data-vault-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Allows seamless cleanup of the lab environment even if files exist
}

# Access Control: Absolute public access block configuration (Core Data Security Pillar)
resource "aws_s3_bucket_public_access_block" "vault_security" {
  bucket = aws_s3_bucket.secure_vault.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-Side Encryption forcing the usage of our dedicated Customer Managed Key
resource "aws_s3_bucket_server_side_encryption_configuration" "vault_encryption" {
  bucket = aws_s3_bucket.secure_vault.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.macie_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true # Minimizes operational costs by reducing AWS KMS API calls
  }
}

# ==============================================================================
# 3. AMAZON MACIE: SERVICE ACTIVATION
# ==============================================================================
resource "aws_macie2_account" "macie_trigger" {
  status                       = "ENABLED"
}

# ==============================================================================
# OUTPUTS
# ==============================================================================
output "s3_bucket_name" {
  value       = aws_s3_bucket.secure_vault.id
  description = "The target S3 bucket name created to upload your sensitive test files"
}

output "kms_key_arn" {
  value       = aws_kms_key.macie_key.arn
  description = "The ARN of the custom KMS Key guarding the storage layer"
}