# for ecs
resource "aws_vpc" "koel-public-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name      = "koel-public-vpc"
    CreatedBy = "terraform"
  }
}

resource "aws_subnet" "ecs-public-subnet1" {
  vpc_id            = aws_vpc.koel-public-vpc.id
  availability_zone = "us-west-2a"

  cidr_block = "10.0.30.0/24"
  tags = {
    Name      = "ecs-public-subnet1"
    CreatedBy = "terraform"
  }
}

resource "aws_subnet" "ecs-public-subnet2" {
  vpc_id            = aws_vpc.koel-public-vpc.id
  availability_zone = "us-west-2b"

  cidr_block = "10.0.31.0/24"
  tags = {
    Name      = "ecs-public-subnet2"
    CreatedBy = "terraform"
  }
}

# for rds
resource "aws_vpc" "koel-rds-vpc" {
  cidr_block           = "172.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name      = "koel-rds-vpc"
    CreatedBy = "terraform"
  }
}

resource "aws_subnet" "koel-rds-subnet1" {
  vpc_id            = aws_vpc.koel-rds-vpc.id
  availability_zone = "us-west-2a"

  cidr_block = "172.0.100.0/24"
  tags = {
    Name      = "koel-rds-subnet1"
    CreatedBy = "terraform"
  }
}

resource "aws_subnet" "koel-rds-subnet2" {
  vpc_id            = aws_vpc.koel-rds-vpc.id
  availability_zone = "us-west-2b"

  cidr_block = "172.0.101.0/24"
  tags = {
    Name      = "koel-rds-subnet2"
    CreatedBy = "terraform"
  }
}

# vpc peering
resource "aws_vpc_peering_connection" "app-rds-connection" {
  peer_vpc_id = aws_vpc.koel-public-vpc.id
  vpc_id      = aws_vpc.koel-rds-vpc.id
  auto_accept = true

  tags = {
    Name      = "app-rds-connection"
    CreatedBy = "terraform"
  }
}

# internet gateway
resource "aws_internet_gateway" "koel-igw" {
  vpc_id = aws_vpc.koel-public-vpc.id
  tags = {
    Name      = "koel-igw"
    CreatedBy = "terraform"
  }
}

resource "aws_network_interface" "koel-public-network-interface" {
  subnet_id = aws_subnet.ecs-public-subnet1.id
  private_ips = [
    "10.0.30.133"
  ]
  security_groups = [
    aws_security_group.koel-sg.id
  ]
}

# route table
resource "aws_route_table" "koel-app-to-rds-rtb" {
  vpc_id = aws_vpc.koel-public-vpc.id

  route {
    cidr_block                = "172.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.app-rds-connection.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.koel-igw.id
  }
  tags = {
    Name      = "koel-app-to-rds-rtb"
    CreatedBy = "terraform"
  }
}

resource "aws_route_table_association" "koel-app-to-rds-rtb-assoc" {
  subnet_id      = aws_subnet.ecs-public-subnet1.id
  route_table_id = aws_route_table.koel-app-to-rds-rtb.id
}

resource "aws_route_table" "koel-rds-rtb" {
  vpc_id = aws_vpc.koel-rds-vpc.id

  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.app-rds-connection.id
  }

  tags = {
    Name      = "koel-app-to-rds-rtb-assoc"
    CreatedBy = "terraform"
  }
}

resource "aws_route_table_association" "koel-rds-rtb-assoc-1" {
  subnet_id      = aws_subnet.koel-rds-subnet1.id
  route_table_id = aws_route_table.koel-rds-rtb.id
}

resource "aws_route_table_association" "koel-rds-rtb-assoc-2" {
  subnet_id      = aws_subnet.koel-rds-subnet2.id
  route_table_id = aws_route_table.koel-rds-rtb.id
}


# security group
resource "aws_security_group" "koel-sg" {
  name        = "koel-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.koel-public-vpc.id

  tags = {
    Name      = "koel-sg"
    CreatedBy = "terraform"
  }
}

resource "aws_security_group_rule" "koel-app-sg-rule1" {
  # アプリケーションへのアクセス許可
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.koel-sg.id
}

resource "aws_security_group_rule" "koel-app-sg-rule2" {
  # アプリケーションへのアクセス許可
  type      = "ingress"
  from_port = 2049
  to_port   = 2049
  protocol  = "tcp"
  cidr_blocks = [
    "10.0.0.0/16"
  ]
  security_group_id = aws_security_group.koel-sg.id
}

resource "aws_security_group_rule" "koel-efs-egress-sg-rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.koel-sg.id
}

resource "aws_security_group_rule" "koel-efs-ingress-sg-rule" {
  type              = "egress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.koel-sg.id
}

resource "aws_security_group" "koel-rds-sg" {
  name        = "koel-rds-sg"
  description = "Allow RDS inboud traffic"
  vpc_id      = aws_vpc.koel-rds-vpc.id

  tags = {
    Name      = "koel-rds-sg"
    CreatedBy = "terraform"
  }
}

resource "aws_security_group_rule" "koel-rds-sg-rule" {
  # アプリケーションからRDSに許可
  type = "ingress"

  description       = "To RDS from App"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.koel-rds-sg.id
}
