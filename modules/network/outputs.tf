output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.lab.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets."
  value       = aws_subnet.private[*].id
}

output "igw_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway, or null if NAT is disabled."
  value       = var.enable_nat ? aws_nat_gateway.nat[0].id : null
}

output "nat_eip" {
  description = "Public IP of the NAT EIP, or null if NAT is disabled."
  value       = var.enable_nat ? aws_eip.nat[0].public_ip : null
}

output "flow_logs_log_group_name" {
  description = "CloudWatch Log Group name for VPC Flow Logs."
  value       = aws_cloudwatch_log_group.vpc_flow.name
}
