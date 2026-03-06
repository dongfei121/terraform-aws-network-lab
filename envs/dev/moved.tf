moved {
  from = aws_vpc.lab
  to   = module.network.aws_vpc.lab
}

moved {
  from = aws_internet_gateway.igw
  to   = module.network.aws_internet_gateway.igw
}

moved {
  from = aws_subnet.public[0]
  to   = module.network.aws_subnet.public[0]
}
moved {
  from = aws_subnet.public[1]
  to   = module.network.aws_subnet.public[1]
}
moved {
  from = aws_subnet.private[0]
  to   = module.network.aws_subnet.private[0]
}
moved {
  from = aws_subnet.private[1]
  to   = module.network.aws_subnet.private[1]
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}
moved {
  from = aws_route_table_association.public_assoc[0]
  to   = module.network.aws_route_table_association.public_assoc[0]
}
moved {
  from = aws_route_table_association.public_assoc[1]
  to   = module.network.aws_route_table_association.public_assoc[1]
}

moved {
  from = aws_eip.nat
  to   = module.network.aws_eip.nat[0]
}
moved {
  from = aws_nat_gateway.nat
  to   = module.network.aws_nat_gateway.nat[0]
}
moved {
  from = aws_route_table.private
  to   = module.network.aws_route_table.private[0]
}
moved {
  from = aws_route_table_association.private_assoc[0]
  to   = module.network.aws_route_table_association.private_assoc[0]
}
moved {
  from = aws_route_table_association.private_assoc[1]
  to   = module.network.aws_route_table_association.private_assoc[1]
}

moved {
  from = aws_security_group.bastion_sg
  to   = module.compute.aws_security_group.bastion_sg
}
moved {
  from = aws_security_group.private_sg
  to   = module.compute.aws_security_group.private_sg
}
moved {
  from = aws_key_pair.lab_key
  to   = module.compute.aws_key_pair.lab_key
}
moved {
  from = aws_instance.bastion
  to   = module.compute.aws_instance.bastion
}
moved {
  from = aws_instance.private1
  to   = module.compute.aws_instance.private1
}
