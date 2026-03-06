terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "project" { type = string }
variable "region" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }

variable "enable_nat" {
  type    = bool
  default = true
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# -------------------------
# VPC
# -------------------------

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "tf-lab-vpc"
    Project = var.project
  }
}

# CKV2_AWS_12: lock down default SG (no ingress/egress)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name    = "tf-default-sg-locked"
    Project = var.project
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name    = "tf-lab-igw"
    Project = var.project
  }
}

# -------------------------
# Subnets
# -------------------------

resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.lab.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = false # CKV_AWS_130

  tags = {
    Name    = "tf-pu
