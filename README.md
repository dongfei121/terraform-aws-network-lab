# Terraform AWS Cloud Network Lab (Multi-AZ)

Production-style AWS networking lab built with Terraform (Cloud9 / AWS Academy friendly).

## What’s inside
- VPC: 10.10.0.0/16
- 2× Public subnets (Multi-AZ)
- 2× Private subnets (Multi-AZ)
- Internet Gateway + Public route table
- Optional NAT Gateway (costly) controlled by `enable_nat`
- Bastion host (public)
- Private EC2 (private subnet) reachable via bastion

## Repo structure
- modules/
  - network/  (VPC, subnets, IGW, route tables, NAT optional)
  - compute/  (bastion, private instance, SGs, key pair)
- envs/
  - dev/      (entrypoint)

## Daily commands
Run from envs/dev:

terraform init
terraform plan
terraform apply

## Cost control: disable NAT
In envs/dev/main.tf set:
enable_nat = false

Then:
terraform plan
terraform apply

Note: With NAT disabled, private instances will not have outbound internet access.

## Notes for restricted lab accounts
Some lab accounts may block EIP release/disassociate. If an EIP becomes “stuck”
but is not associated with any ENI, you can remove it from Terraform state to
keep workflows unblocked:

terraform state rm module.network.aws_eip.nat[0]
