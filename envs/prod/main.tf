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
  type = string
}

variable "region" {
  type = string
}

variable "public_key_openssh" {
  type = string
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

  project                  = var.project
  region                   = var.region
  vpc_cidr                 = "10.10.0.0/16"
  azs                      = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs      = ["10.10.10.0/24", "10.10.11.0/24"]
  private_subnet_cidrs     = ["10.10.20.0/24", "10.10.21.0/24"]
  enable_nat               = false
  flow_logs_retention_days = 365

  tags = {
    Environment = "dev"
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
}

# -------------------------
# Outputs
# -------------------------

output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "nat_eip" {
  value = module.network.nat_eip
}

output "bastion_public_ip" {
  value = module.compute.bastion_public_ip
}

output "private1_ip" {
  value = module.compute.private1_ip
}

output "ssh_command" {
  value = module.compute.ssh_command
}
