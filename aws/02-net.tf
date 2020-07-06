### Networks

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "example" {
  count = 2

  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

### Routing Table

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
}

resource "aws_route_table_association" "example" {
  count = length(aws_subnet.example)

  route_table_id = aws_route_table.example.id
  subnet_id      = aws_subnet.example[count.index].id
}

### DNS Zone

resource "aws_route53_zone" "example_local" {
  name = "example.local"

  vpc {
    vpc_id = aws_vpc.example.id
  }
}
