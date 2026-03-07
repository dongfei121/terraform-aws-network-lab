variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where compute resources will be created."
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for bastion host."
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for private instance."
  type        = string
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