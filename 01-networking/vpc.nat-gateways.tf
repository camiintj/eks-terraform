resource "aws_nat_gateway" "this" {
  count         = length(aws_subnet.public)

  allocation_id = aws_eip.this[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = { Name = "${var.vpc.name}-${var.vpc.nat_gateway_name}-${aws_subnet.public[count.index].availability_zone}"}
  
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.this]
}