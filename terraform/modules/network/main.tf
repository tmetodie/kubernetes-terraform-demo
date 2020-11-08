# VPC
resource "aws_vpc" "vpc" {
    cidr_block           = var.cidr_block
    enable_dns_hostnames = true
    tags = merge({Name="${var.naming}-vpc"}, var.common_tags)

    lifecycle {
        create_before_destroy = true
        ignore_changes        = [
        tags,
        ]
    }
}

# Public subnets
resource "aws_subnet" "public" {
  count = var.az_count

  availability_zone       = join("", [var.region, element(var.az_zones, count.index)])
  cidr_block              = cidrsubnet(var.cidr_block, 9, count.index)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true

  tags = {
    Name                                      = "${var.naming}-sbnt-pub-${count.index}"
    "kubernetes.io/role/elb"                  = "1"
    "kubernetes.io/role/alb-ingress"          = "1"
    "kubernetes.io/cluster/${var.naming}-eks" = "shared"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count = var.az_count

  availability_zone       = join("", [var.region, element(var.az_zones, count.index)])
  cidr_block              = cidrsubnet(var.cidr_block, 9, count.index+var.az_count)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name                                       = "${var.naming}-sbnt-priv-${count.index}"
      "kubernetes.io/role/internal-elb"          = "1"
      "kubernetes.io/role/alb-ingress"           = "1"
      "kubernetes.io/cluster/${var.naming}-eks" = "shared"
    })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    tags = merge({Name="${var.naming}-igw"}, var.common_tags)
}

# NAT Gateway Elastic IP
resource "aws_eip" "ngw_eip" {
    vpc        = true
    depends_on = [aws_internet_gateway.igw]

    tags = merge({Name="${var.naming}-ngw-eip"}, var.common_tags)
}

# NAT Gateway
resource "aws_nat_gateway" "ngw" {
    allocation_id = aws_eip.ngw_eip.id
    subnet_id     = aws_subnet.public[0].id

    tags = merge({Name="${var.naming}-ngw"}, var.common_tags)
}

# Public Route Table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.vpc.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
    }

    tags = merge({Name="${var.naming}-public"}, var.common_tags)
}

# Private Route Table (default)
resource "aws_default_route_table" "private" {
    default_route_table_id = aws_vpc.vpc.default_route_table_id

    route {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.ngw.id
    }

    tags = merge({Name="${var.naming}-private"}, var.common_tags)
}

# Route table associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_default_route_table.private.id
}
