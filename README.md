# Terraform AWS Cloud Network Lab (Multi-AZ)

一个使用 Terraform 构建的模块化 AWS 网络实验项目，适用于 **Cloud9 / AWS Academy / Vocareum** 等实验环境。  
A modular, production-style AWS networking lab built with Terraform, designed for **Cloud9 / AWS Academy / Vocareum-style lab environments**.

这个项目重点展示了：  
This project focuses on:

- Terraform 模块化设计 / Reusable Terraform modules
- 环境分层组织方式 / Clean environment separation
- AWS 网络基础设施实践 / Practical AWS networking fundamentals
- 成本控制思路（可关闭 NAT） / Cost awareness with optional NAT
- GitHub Actions 持续集成检查 / CI checks with GitHub Actions
- 更接近真实工程项目的结构化写法 / Production-style project structure

---

## Architecture overview | 架构概览

This project provisions a small AWS environment with:  
本项目会创建一个小型 AWS 网络环境，包括：

- **1 VPC**: `10.10.0.0/16`
- **2 public subnets** across 2 Availability Zones  
  **2 个跨可用区的公有子网**
- **2 private subnets** across 2 Availability Zones  
  **2 个跨可用区的私有子网**
- **Internet Gateway**
- **Public route table**
- **Optional NAT Gateway** controlled by `enable_nat`  
  **可选 NAT Gateway**，通过 `enable_nat` 控制
- **Bastion EC2 instance** in a public subnet  
  **位于公有子网中的 Bastion 主机**
- **Private EC2 instance** in a private subnet  
  **位于私有子网中的私有 EC2**
- **VPC Flow Logs** to CloudWatch Logs
- **KMS-encrypted CloudWatch Log Group**
- **IAM instance profile** attached to EC2 instances
- **Security groups** with restricted ingress / controlled egress  
  **限制入站、受控出站的安全组规则**

---

## Architecture diagram | 架构图

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


Project structure | 项目结构
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

Module responsibilities | 模块职责
modules/network

Responsible for networking resources:
负责网络资源：

VPC

public/private subnets

Internet Gateway

public/private route tables

optional NAT Gateway

VPC Flow Logs

CloudWatch Log Group + KMS encryption

modules/compute

Responsible for compute and access resources:
负责计算与访问相关资源：

bastion EC2

private EC2

security groups

EC2 key pair

IAM role / instance profile

envs/dev

Environment entrypoint that wires modules together for a development/lab deployment.
开发/实验环境入口文件，用于把各模块组合起来完成部署。

Why this project matters | 为什么这个项目有价值

This project demonstrates Terraform skills beyond a single flat file.
这个项目展示的不只是“把资源写在一个 tf 文件里”，而是更接近真实工程的 Terraform 实践：

modular design / 模块化设计

environment-based structure / 环境分层结构

clear separation of networking and compute / 网络与计算解耦

cost control choices / 成本控制设计

security-minded defaults / 更安全的默认配置

CI validation in GitHub Actions / GitHub Actions 持续集成校验

It is intentionally built to be portfolio-friendly while still practical in lab environments.
它既适合作为作品集展示，也适合在实验环境中实际运行。

Project highlights | 项目亮点

Modular Terraform design with separate network and compute modules
使用独立的 network 与 compute 模块实现模块化设计

Multi-AZ public/private subnet layout
跨可用区的公有/私有子网布局

Bastion-based access to private EC2
通过 Bastion 主机访问私有 EC2

Optional NAT Gateway for cost control
支持关闭 NAT 以节省费用

VPC Flow Logs enabled with CloudWatch + KMS encryption
启用 VPC Flow Logs，并使用 CloudWatch + KMS 加密

IAM instance profile attached to EC2 instances
为 EC2 绑定 IAM Instance Profile

Security-minded defaults (IMDSv2, encrypted root volumes, controlled egress)
更安全的默认配置（IMDSv2、根卷加密、受控出站）

CI checks with GitHub Actions, TFLint, and Checkov
使用 GitHub Actions、TFLint、Checkov 做持续集成检查

How to use | 使用方法
1. Clone the repository | 克隆仓库
git clone git@github.com:dongfei121/terraform-aws-network-lab.git
cd terraform-aws-network-lab

2. Go to the dev environment | 进入 dev 环境
cd envs/dev

3. Prepare variables | 准备变量

Set values such as:
设置如下变量：

project

region

public_key_openssh

If using a local tfvars file, keep it out of version control.
如果使用本地 tfvars 文件，请不要提交到版本控制中。

4. Initialize Terraform | 初始化 Terraform
terraform init

5. Review the plan | 查看执行计划
terraform plan

6. Apply | 部署资源
terraform apply

Typical outputs | 常见输出

After apply, Terraform outputs useful values such as:
部署完成后，Terraform 会输出一些常用信息，例如：

vpc_id

public_subnet_ids

private_subnet_ids

bastion_public_ip

private1_ip

ssh_command

Example | 示例：

ssh -i id_rsa ec2-user@<bastion_public_ip>


Then from the bastion host, you can SSH into the private instance using its private IP.
之后你可以从 bastion 主机再 SSH 到私有 EC2。

Cost control | 成本控制
Disable NAT to save money | 关闭 NAT 节省费用

In envs/dev/main.tf, set:
在 envs/dev/main.tf 中设置：

enable_nat = false


Then run:
然后执行：

terraform plan
terraform apply

Important note | 重要说明

With NAT disabled, private instances will not have outbound internet access.
关闭 NAT 后，私有子网中的实例将无法访问外网。

This is often acceptable in lab environments and is useful when the goal is to preserve architecture while minimizing spend.
这在实验环境里通常是可接受的，适合“保留架构但尽量省钱”的场景。

Notes for restricted lab accounts | 受限实验账号说明

Some sandbox / academy / restricted AWS accounts may block certain actions around Elastic IPs, especially release or disassociation.
某些沙箱 / 学院 / 受限 AWS 账号可能会限制 Elastic IP 的释放或解绑。

If an EIP becomes stuck in Terraform state but is no longer actually attached to a resource, you can remove it from state:
如果某个 EIP 在 Terraform state 中卡住了，但实际上已经没有关联资源，可以把它从 state 中移除：

terraform state rm module.network.aws_eip.nat[0]


This helps unblock Terraform workflows in constrained lab environments.
这样可以避免实验环境里的 Terraform 流程被卡住。

Security notes | 安全说明

This project includes some deliberate lab/demo tradeoffs:
这个项目包含一些为了实验环境而做的取舍：

The bastion host uses a public IP so SSH access is possible in a lab.
Bastion 主机使用公网 IP，这样实验环境里才能直接 SSH。

Checkov skips are configured in CI for a few lab-specific exceptions.
在 CI 中对少量实验场景特例做了 Checkov 跳过配置。

Security groups avoid unrestricted -1 egress and instead allow common outbound traffic explicitly.
安全组避免使用无限制 -1 出站，而是显式放行常见流量。

IMDSv2 is enforced on EC2 instances.
EC2 强制启用 IMDSv2。

Root volumes are encrypted.
根卷启用加密。

IAM instance profiles are attached to instances.
EC2 挂载了 IAM Instance Profile。

In a stricter production environment, you would likely:
如果是更严格的生产环境，通常还会继续做这些优化：

replace bastion SSH with SSM Session Manager
用 SSM Session Manager 代替 SSH bastion

avoid public IPs entirely
完全避免公网 IP

use remote state backend
使用远程 state backend

tighten KMS policies further
进一步收紧 KMS 策略

use separate dev/stage/prod environments
区分 dev / stage / prod 多环境

CI / Quality checks | 持续集成与质量检查

GitHub Actions runs the following checks on pushes and pull requests:
GitHub Actions 会在 push 和 pull request 时执行以下检查：

Terraform formatting

Terraform validation

TFLint

Checkov

This helps keep the codebase consistent and reduces broken changes.
这样可以保持代码风格一致，并减少错误改动进入主分支。

Future improvements | 后续可扩展方向

Possible next steps for this project:
这个项目后续还可以继续扩展：

add envs/prod

introduce remote backend with S3 + DynamoDB

replace bastion access with AWS Systems Manager

add reusable tagging strategy across all modules

generate architecture diagram image

add PR-based Terraform plan output

support multiple private instances via count or for_each

对应中文说明：

增加 envs/prod

使用 S3 + DynamoDB 作为远程 backend

用 AWS Systems Manager 替代 bastion SSH

为所有模块增加统一标签策略

生成真正的架构图图片

在 PR 中自动输出 Terraform plan

使用 count 或 for_each 支持多个私有实例

Author | 作者

Fei Dong
GitHub: dongfei121

License | 说明

This project is for learning, lab practice, and portfolio demonstration.
本项目主要用于学习、实验练习和作品集展示。