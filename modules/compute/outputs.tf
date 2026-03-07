output "bastion_public_ip" {
  description = "Public IP of the bastion instance."
  value       = aws_instance.bastion.public_ip
}

output "private1_ip" {
  description = "Private IP of the private instance."
  value       = aws_instance.private1.private_ip
}

output "ssh_command" {
  description = "Convenient SSH command for bastion access."
  value       = "ssh -i id_rsa ec2-user@${aws_instance.bastion.public_ip}"
}

output "my_ip_cidr" {
  description = "Detected or provided client IP CIDR allowed for bastion SSH."
  value       = local.my_ip_cidr
}