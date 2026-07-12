# GRC-Compliance Baseline

A Terraform baseline that deploys and enforces security and compliance controls in a live AWS account, closing the gap between written policy and what's actually configured.

## The Problem

Most GRC programs document what security controls *should* look like, then rely on manual checks, or nothing at all, to confirm they're actually in place. This project takes the opposite approach: define the controls as code, deploy them, and let the infrastructure enforce the policy instead of a spreadsheet.

## What This Project Does

This Terraform baseline configures a live AWS account with the following controls:

- **IAM Password Policy** — enforces minimum length, complexity, rotation, and reuse rules across all IAM users
- **S3 Bucket Configuration** — applies secure defaults including encryption, versioning, and public access blocking
- **CloudTrail Logging** — enables multi-region logging so account activity is captured consistently regardless of where an action occurs
- **AWS Config Managed Rules** — deploys a set of AWS Config rules that continuously monitor the account for drift away from the baseline

## Results

Before this baseline was deployed, the target AWS account scored **40%** on a standard compliance check.

After deployment and remediation of the flagged findings, the same account scored **78%**.

That's not a theoretical improvement. It's a real account, a real baseline, and a real before-and-after measurement.

## Why I Built This

I kept running into the same gap in GRC work: a control is written down as a policy, but nobody's actually verifying it's configured correctly in the environment it's supposed to protect. This project is my answer to that gap, infrastructure as code applied specifically to compliance requirements, so the control isn't just documented, it's deployed and continuously checked.

## Tech Stack

- **Terraform** — infrastructure as code for all resource configuration
- **AWS** — IAM, S3, CloudTrail, AWS Config
- **AWS Config Managed Rules** — continuous compliance monitoring

## How to Use This

1. Clone this repository
2. Configure your AWS credentials (this project assumes an existing AWS account with appropriate permissions)
3. Review and adjust variables in `variables.tf` to match your account and naming conventions
4. Run `terraform init` to initialize the working directory
5. Run `terraform plan` to review the changes that will be made
6. Run `terraform apply` to deploy the baseline

**Note:** Review all planned changes carefully before applying to a production account. This baseline makes real changes to IAM policy, S3 configuration, and logging setup.

## What I'd Build Next

- Extend the AWS Config rule set to cover additional CIS AWS Foundations Benchmark controls
- Add automated remediation for common drift scenarios instead of just detection
- Build a small dashboard that pulls the AWS Config compliance score automatically, rather than checking it manually

---

Built as part of my GRC Engineering Portfolio, where I apply automation and infrastructure-as-code practices to compliance and security control problems.

[GRC Engineering Portfolio](https://gitlab.com/doneal78-group) | [LinkedIn](https://linkedin.com/in/david-oneal)
