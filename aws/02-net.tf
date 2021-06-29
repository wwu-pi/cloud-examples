### Networks

locals {
  subnets = 3
}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "example"
  }
}

resource "aws_subnet" "example_public" {
  count = local.subnets

  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = format("example-public-%02d", count.index + 1)

    "kubernetes.io/role/elb"        = "1"
    "kubernetes.io/cluster/example" = "owned"
  }
}

resource "aws_subnet" "example_private" {
  count = local.subnets

  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, 3 + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = format("example-private-%02d", count.index + 1)

    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/example"   = "owned"
  }
}

### Routing Table

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example"
  }
}

resource "aws_eip" "nat_ip" {
  count = local.subnets
  vpc   = true
}

resource "aws_nat_gateway" "example" {
  count = local.subnets

  allocation_id = aws_eip.nat_ip[count.index].id
  subnet_id     = aws_subnet.example_public[count.index].id

  tags = {
    Name = format("example-%02d", count.index + 1)
  }

  depends_on = [aws_internet_gateway.example]
}

resource "aws_route_table" "example_public" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-public"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
}

resource "aws_route_table" "example_private" {
  count = local.subnets

  vpc_id = aws_vpc.example.id

  tags = {
    Name = format("example-private-%02d", count.index + 1)
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example[count.index].id
  }
}

resource "aws_route_table_association" "example_public" {
  count = local.subnets

  route_table_id = aws_route_table.example_public.id
  subnet_id      = aws_subnet.example_public[count.index].id
}

resource "aws_route_table_association" "example_private" {
  count = local.subnets

  route_table_id = aws_route_table.example_private[count.index].id
  subnet_id      = aws_subnet.example_private[count.index].id
}
