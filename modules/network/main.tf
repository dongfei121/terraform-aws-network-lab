terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "enable_nat" {
  type    = bool
  default = true
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "tf-lab-vpc"
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
  count             = length(var.azs)
  vpc_id            = aws_vpc.lab.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.public_subnet_cidrs[count.index]

  # CKV_AWS_130: do NOT auto-assign public IP by default
  # Bastion can still have a public IP via associate_public_ip_address = true
  map_public_ip_on_launch = false

  tags = {
    Name    = "tf-public-${var.azs[count.index]}"
    Tier    = "public"
    Project = var.project
  }
}

resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.lab.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]

  tags = {
    Name    = "tf-private-${var.azs[count.index]}"
    Tier    = "private"
    Project = var.project
  }
}

# -------------------------
# Route tables (Public)
# -------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "tf-public-rt"
    Project = var.project
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# NAT (optional)
# -------------------------

resource "aws_eip" "nat" {
  count  = var.enable_nat ? 1 : 0
  domain = "vpc"

  tags = {
    Name    = "tf-nat-eip"
    Project = var.project
  }
}

resource "aws_nat_gateway" "nat" {
  count         = var.enable_nat ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name    = "tf-natgw"
    Project = var.project
  }
}

resource "aws_route_table" "private" {
  count  = var.enable_nat ? 1 : 0
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = {
    Name    = "tf-private-rt"
    Project = var.project
  }
}

resource "aws_route_table_association" "private_assoc" {
  count          = var.enable_nat ? length(var.azs) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# -------------------------
# VPC Flow Logs (CKV2_AWS_11)
# -------------------------

resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/${var.project}-flowlogs"
  retention_in_days = 7

  tags = {
    Project = var.project
  }
}

data "aws_iam_policy_document" "vpc_flow_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_flow_role" {
  name               = "${var.project}-vpc-flowlogs-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_assume.json
}

data "aws_iam_policy_document" "vpc_flow_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs
