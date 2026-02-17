data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["nsse-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = [false]
  }
}

#FILTER https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSubnets.html
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets

