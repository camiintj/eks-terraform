data "aws_subnets" "private" {
  filter {
    name   = "map-public-ip-on-launch"
    values = [false]
  }

}

#FILTER https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSubnets.html
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets

