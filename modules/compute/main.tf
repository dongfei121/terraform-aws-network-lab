terraform {
  required_version = ">= 1.5.0"

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

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "bastion_public_ip_cidr" {
  description = "Optional. If empty, auto-detect via external provider."
  type        = string
  default     = ""
}

variable "public_key_openssh" {
  description = "SSH public key content in OpenSSH format (ssh-ed25519 ...)"
  type        = string
}

provider "aws" {
  region = var.region
}

data "external" "myip" {
  program = [
    "bash",
    "-lc",
    "echo '{\"ip\":\"'$(curl -s https://checkip.amazonaws.com | tr -d \"\\n\")'\"}'"
  ]
}

locals {
  my_ip_cidr = var.bastion_public_ip_cidr != "" ? var.bastion_public_ip_cidr : "${data.external.myip.result.ip}/32"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${var.project}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_security_group" "bastion_sg" {
  name        = "tf-bastion-sg"
  description = "Bastion SG - allow SSH from my current public IP only"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from my current public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "tf-bastion-sg"
    Project = var.project
  }
}

resource "aws_key_pair" "lab_key" {
  key_name   = "tf-lab-key"
  public_key = var.public_key_openssh
}

# checkov:skip=CKV_AWS_88: Bastion host requires a public IP for SSH access (lab/demo)
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.lab_key.key_name

  # CKV2_AWS_41 (IAM role attached)
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # CKV_AWS_135 / CKV_AWS_126
  ebs_optimized = true
  monitoring    = true

  # CKV_AWS_79 (IMDSv2)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # CKV_AWS_8 (EBS encryption)
  root_block_device {
    encrypted = true
  }

  tags = {
    Name    = "tf-bastion"
    Project = var.project
    Role    = "bastion"
  }
}

resource "aws_security_group" "private_sg" {
  name        = "tf-private-sg"
  description = "Private instance SG - allow SSH from bastion only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH from bastion SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "tf-private-sg"
    Project = var.project
  }
}

resource "aws_instance" "private1" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.lab_key.key_name

  # CKV2_AWS_41 (IAM role attached)
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # CKV_AWS_135 / CKV_AWS_126
  ebs_optimized = true
  monitoring    = true

  # CKV_AWS_79 (IMDSv2)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # CKV_AWS_8 (EBS encryption)
  root_block_device {
    encrypted = true
  }

  tags = {
    Name    = "tf-private-ec2"
    Project = var.project
    Role    = "private"
  }
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "private1_ip" {
  value = aws_instance.private1.private_ip
}

output "ssh_command" {
  value = "ssh -i id_rsa ec2-user@${aws_instance.bastion.public_ip}"
}

output "my_ip_cidr" {
  value = local.my_ip_cidr
}
