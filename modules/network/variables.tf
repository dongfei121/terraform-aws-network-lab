variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones to use."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "public_subnet_cidrs must have the same length as azs."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "private_subnet_cidrs must have the same length as azs."
  }
}

variable "enable_nat" {
  description = "Whether to create a NAT Gateway for private subnets."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Retention in days for VPC Flow Logs CloudWatch log group."
  type        = number
  default     = 365
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {}
}
