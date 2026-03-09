output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.lab.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_eip" {
  description = "The EIP of the NAT gateway, if enabled"
  value       = var.enable_nat ? aws_eip.nat[0].public_ip : null
}

output "vpc_flow_log_group" {
  description = "The CloudWatch log group for VPC flow logs"
  value       = aws_cloudwatch_log_group.vpc_flow.name
}
