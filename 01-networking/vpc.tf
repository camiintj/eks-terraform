resource "aws_vpc" "this" {
  cidr_block = var.vpc.cidr

  tags = { Name = var.vpc.name 
  
  }

}
