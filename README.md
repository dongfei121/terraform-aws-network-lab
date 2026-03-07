# Terraform AWS Cloud Network Lab (Multi-AZ)

A modular, production-style AWS networking lab built with Terraform.  
Designed for **Cloud9 / AWS Academy / Vocareum-style lab environments**, with a focus on:

- reusable Terraform modules
- clean environment separation
- cost awareness
- CI checks with GitHub Actions
- practical AWS networking fundamentals

---

## Architecture diagram

```text
                           Internet
                               |
                               |
                        +-------------+
                        |     IGW     |
                        +-------------+
                               |
                 +-------------------------------+
                 |            VPC                |
                 |         10.10.0.0/16         |
                 |                               |
                 |   +-----------------------+   |
                 |   |   Public Subnets      |   |
                 |   |  10.10.10.0/24        |   |
                 |   |  10.10.11.0/24        |   |
                 |   |                       |   |
                 |   |  Bastion EC2         |   |
                 |   +-----------------------+   |
                 |               |               |
                 |               | SSH           |
                 |               v               |
                 |   +-----------------------+   |
                 |   |   Private Subnets     |   |
                 |   |  10.10.20.0/24        |   |
                 |   |  10.10.21.0/24        |   |
                 |   |                       |   |
                 |   |  Private EC2         |   |
                 |   +-----------------------+   |
                 |                               |
                 |   Optional NAT Gateway        |
                 |   (enable_nat = true/false)   |
                 +-------------------------------+

                 VPC Flow Logs -> CloudWatch Logs -> KMS Encryption


This project provisions a small AWS environment with:

- **1 VPC**: `10.10.0.0/16`
- **2 public subnets** across 2 Availability Zones
- **2 private subnets** across 2 Availability Zones
- **Internet Gateway**
- **Public route table**
- **Optional NAT Gateway** controlled by `enable_nat`
- **Bastion EC2 instance** in a public subnet
- **Private EC2 instance** in a private subnet
- **VPC Flow Logs** to CloudWatch Logs
- **KMS-encrypted CloudWatch Log Group**
- **IAM instance profile** attached to EC2 instances
- **Security groups** with restricted ingress / controlled egress

---

## Project structure

```text
.
├── modules
│   ├── network
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── compute
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── envs
│   └── dev
│       ├── main.tf
│       ├── moved.tf
│       └── terraform.tfvars
├── .github
│   └── workflows
│       └── terraform.yml
└── README.md

```md
## Project highlights

- Modular Terraform design with separate `network` and `compute` modules
- Multi-AZ public/private subnet layout
- Bastion-based access to private EC2
- Optional NAT Gateway for cost control
- VPC Flow Logs enabled with CloudWatch + KMS encryption
- IAM instance profile attached to EC2 instances
- Security-minded defaults (IMDSv2, encrypted root volumes, controlled egress)
- CI checks with GitHub Actions, TFLint, and Checkov