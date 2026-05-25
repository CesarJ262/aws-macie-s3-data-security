# AWS Data Security: Automated Auditing with Amazon Macie and Custom KMS

## 📌 Project Overview
This project implements a secure, cloud-native data governance and protection architecture. It deploys an **Amazon S3** storage solution hardened with a Customer Managed Key (CMK) via **AWS KMS** and integrates **Amazon Macie** to perform automated discovery and classification of sensitive data, such as Personally Identifiable Information (PII) and financial records (Credit Cards).

This setup reflects industry standards for data-at-rest protection and continuous compliance auditing (e.g., PCI-DSS, GDPR).

---

## 🏗️ Architecture Blueprint

The architecture follows a defense-in-depth strategy, isolating sensitive storage and enforcing strict cryptographic boundaries:

1. **Amazon S3 (Data Vault):** Configured with absolute public access blocks and default server-side encryption.
2. **AWS KMS (Cryptographic Shield):** A Customer Managed Key (CMK) with a strict Key Policy that delegates decryption capabilities exclusively to authorized entities.
3. **Amazon Macie (Automated Auditor):** A machine learning-powered security service that assumes its localized Service-Linked Role to inspect, analyze, and flag sensitive data patterns (utilizing regex and Luhn algorithm checks).

---

## 🛠️ Security Configuration & Hardening

### 1. The S3 Hardening
The S3 Bucket is deployed with a `Public Access Block` configuration to mitigate data leakage risks:

### 2. The Least-Privilege KMS Key Policy
To protect the encryption material against *Confused Deputy* attacks, the KMS Key Policy restricts `kms:Decrypt` actions specifically to the Macie Service-Linked Role associated with the local AWS Account:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow Macie Service Role Access",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::YOUR_ACCOUNT_ID:role/aws-service-role/[macie.amazonaws.com/AWSServiceRoleForAmazonMacie](https://macie.amazonaws.com/AWSServiceRoleForAmazonMacie)"
      },
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}
```

## Execution Order

1. Navigate to `infra/`, run `terraform init` and `terraform apply`.
2. Upload your sensitive test file to the generated S3 bucket.
3. Navigate to `security-jobs/`, run `terraform init` and `terraform apply` to dispatch the scan.
