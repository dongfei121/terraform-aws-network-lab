terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "terraform-network-lab-state-dongfei121"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}

# -------------------------
# Input variables
# -------------------------

variable "project" {
  type        = string
  description = "The project name"
}

variable "region" {
  type        = string
  description = "The primary AWS region"
}

variable "secondary_region" {
  type        = string
  description = "The secondary AWS region"
  default     = "us-west-2"
}

variable "public_key_openssh" {
  type        = string
  description = "SSH public key for EC2 instances"
}

# -------------------------
# Provider
# -------------------------

provider "aws" {
  region = var.region
}

# -------------------------
# Network module
# -------------------------

module "network" {
  source = "../../modules/network"

  project              = var.project
  region               = var.region
  secondary_region     = var.secondary_region
  vpc_cidr             = "10.10.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.10.10.0/24", "10.10.11.0/24"]
  private_subnet_cidrs = ["10.10.20.0/24", "10.10.21.0/24"]
  enable_nat           = false
  tags = {
    Environment = "prod"
    Owner       = "dongfei121"
  }
}

# -------------------------
# Compute module
# -------------------------

module "compute" {
  source = "../../modules/compute"

  project            = var.project
  region             = var.region
  vpc_id             = module.network.vpc_id
  public_subnet_id   = module.network.public_subnet_ids[0]
  private_subnet_id  = module.network.private_subnet_ids[0]
  public_key_openssh = var.public_key_openssh

  # 关键接力：将 network 模块的输出传给 compute 模块
  vpc_id_secondary    = module.network.vpc_id_secondary
  secondary_subnet_id = module.network.secondary_subnet_id
}

# -------------------------
# Outputs
# -------------------------

output "bastion_public_ip" {
  value = module.compute.bastion_public_ip
}

output "secondary_private_ip" {
  value = module.compute.secondary_private_ip
}

output "ssh_command" {
  value = module.compute.ssh_command
}