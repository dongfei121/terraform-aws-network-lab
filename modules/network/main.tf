terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  common_tags = merge(
    {
      Project = var.project
    },
    var.tags
  )
}

# -------------------------
# VPC
# -------------------------

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "tf-lab-vpc"
  })
}

# Lock down the default SG
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.lab.id

  tags = merge(local.common_tags, {
    Name = "tf-default-sg-locked"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab.id

  tags = merge(local.common_tags, {
    Name = "tf-lab-igw"
  })
}

# -------------------------
# Subnets
# -------------------------

resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.lab.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "tf-public-${var.azs[count.index]}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.lab.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]

  tags = merge(local.common_tags, {
    Name = "tf-private-${var.azs[count.index]}"
    Tier = "private"
  })
}

# -------------------------
# Public routing
# -------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "tf-public-rt"
  })
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# NAT / private routing
# -------------------------

resource "aws_eip" "nat" {
  count  = var.enable_nat ? 1 : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "tf-nat-eip"
  })
}

resource "aws_nat_gateway" "nat" {
  count         = var.enable_nat ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "tf-natgw"
  })
}

resource "aws_route_table" "private" {
  count  = var.enable_nat ? 1 : 0
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = merge(local.common_tags, {
    Name = "tf-private-rt"
  })
}

resource "aws_route_table_association" "private_assoc" {
  count          = var.enable_nat ? length(var.azs) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# -------------------------
# VPC Flow Logs
# -------------------------

data "aws_iam_policy_document" "cw_kms_key_policy" {
  statement {
    sid    = "AllowAccountRootKeyAdministration"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchLogsUseKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}

resource "aws_kms_key" "cw_logs" {
  description             = "KMS key for CloudWatch Logs encryption (${var.project})"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cw_kms_key_policy.json

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/${var.project}/flow-logs"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = aws_kms_key.cw_logs.arn

  tags = local.common_tags
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

resource "aws_iam_role_policy" "vpc_flow_policy" {
  name = "${var.project}-vpc-flowlogs-policy"
  role = aws_iam_role.vpc_flow_role.id

  # least privilege: scope to the single log group
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteFlowLogsToSpecificLogGroup"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          aws_cloudwatch_log_group.vpc_flow.arn,
          "${aws_cloudwatch_log_group.vpc_flow.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  vpc_id               = aws_vpc.lab.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow.arn
  iam_role_arn         = aws_iam_role.vpc_flow_role.arn

  tags = merge(local.common_tags, {
    Name = "${var.project}-vpc-flowlogs"
  })
}
