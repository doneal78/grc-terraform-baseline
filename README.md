# Terraform Compliance Baseline

Infrastructure as code that deploys a complete AWS security compliance baseline to an AWS account in a single command. Covers IAM password policy enforcement, compliant S3 buckets, CloudTrail audit logging, and AWS Config continuous compliance monitoring with four managed rules.

Part of the OracleRecon GRC Engineering Portfolio.

---

## What it deploys

**IAM Account Password Policy**

Minimum 14 character length, uppercase, lowercase, numbers, and symbols required, 90 day maximum password age, 24 password reuse prevention. Satisfies SOC 2 CC6.1 and NIST 800-53 AC-2 requirements.

**Compliant S3 Bucket**

AES-256 server-side encryption, versioning enabled, all four public access block flags set to true. Tagged with Project, Environment, ManagedBy, and ComplianceScope for audit traceability.

**CloudTrail**

Multi-region trail capturing all management events and global service events including IAM. Log file validation enabled so any tampering with log files is detectable. Dedicated encrypted S3 bucket with a bucket policy granting CloudTrail write access.

**AWS Config with four managed rules**

Continuous compliance monitoring evaluating every S3 bucket and IAM configuration automatically whenever resources change.

S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED: flags any unencrypted bucket.

S3_BUCKET_PUBLIC_READ_PROHIBITED: flags any publicly readable bucket.

MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS: flags any IAM user without MFA.

IAM_ROOT_ACCESS_KEY_CHECK: flags if root access keys exist.

---

## Compliance score impact

The Project 2 compliance checker scored the OracleRecon account at 40% AT RISK before this baseline was applied. After applying it, the same checker confirmed a score of 78% NEEDS IMPROVEMENT. The remaining failures are one intentionally misconfigured test bucket and MFA on the lab IAM user which requires physical device setup.

---

## Setup

Install Terraform 1.15 or later. Add the binary to PATH.

Configure AWS credentials:

```
aws configure
```

The IAM user needs these permissions: IAMFullAccess, AmazonS3FullAccess, AWSCloudTrail_FullAccess, AWSConfigUserAccess, and the custom inline policy GRCConfigWriteAccess covering Config write actions.

---

## Usage

```
terraform init
terraform plan
terraform apply
```

Type yes when prompted to confirm the apply.

---

## Destroy

```
terraform destroy
```

---

## Files

main.tf contains all resource definitions across four sections: IAM password policy, compliant S3 bucket with versioning and encryption, CloudTrail with dedicated log bucket, and AWS Config with recorder, delivery channel, and four managed rules.

.terraform.lock.hcl pins the AWS and Random provider versions.

.gitignore excludes the .terraform provider directory, state files, and plan files from version control.

---

## Key concepts demonstrated

Terraform declarative infrastructure: define the desired state, let Terraform calculate what needs to change.

Resource references and depends_on: CloudTrail requires the S3 bucket policy before it can be created. AWS Config requires the recorder before the delivery channel before the recorder status.

jsonencode for bucket policies: S3 bucket policies written inline in HCL rather than separate JSON files.

State management: terraform import used to bring existing resources under Terraform management without recreation.

---

## Related projects

Project 2 Compliance Checker: https://github.com/doneal78/grc-compliance-checker

Run the compliance checker before and after applying this baseline to see the score improvement in real numbers.

Full portfolio: https://github.com/doneal78
