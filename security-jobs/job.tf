# ==============================================================================
# PHASE 2: EPHEMERAL COMPLIANCE AUDITING JOB
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
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# Macie Classification Job targeting the pre-existing infrastructure
resource "aws_macie2_classification_job" "on_demand_scan_job" {
  job_type = "ONE_TIME"
  name     = "on-demand-s3-pii-scan"

  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = ["aws-macie-data-vault-${data.aws_caller_identity.current.account_id}"] # References the bucket created in Phase 1
    }
  }
}