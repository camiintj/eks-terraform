output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "The IDs of the NAT Gateways"
  value       = aws_nat_gateway.this[*].id
}

output "public_subnets_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id  
}

output "private_subnets_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.private[*].id  
}