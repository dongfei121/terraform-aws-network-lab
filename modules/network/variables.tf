variable "project" {
  type        = string
  description = "The project name"
}

variable "region" {
  type        = string
  description = "The AWS region"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRs for the public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRs for the private subnets"
}

variable "enable_nat" {
  type        = bool
  description = "Whether to enable a NAT gateway for private subnets"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Common tags to be applied to resources"
  default     = {}
}

variable "flow_logs_retention_days" {
  type        = number
  description = "Retention period for VPC flow logs in CloudWatch"
  default     = 365
}
