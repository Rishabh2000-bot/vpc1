 provider "aws" {
  region = "ap-south-1"
  profile = "harsh"
}

#keypair
resource "tls_private_key" "private_key" {
  algorithm   = "RSA"
  rsa_bits = 4096

}

resource "aws_key_pair" "public_key" {
  key_name   = "public_key"
  public_key = tls_private_key.private_key.public_key_openssh
}

#vpc
resource "aws_vpc" "myvpc" {
  cidr_block           = "192.168.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
tags = {
    Name = "myvpc"
}
}

#subnet
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "192.168.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1a"

tags = {
   Name = "subnet1"
}
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "ap-south-1b"

tags = {
   Name = "subnet2"
}
}

#securitygrp
resource "aws_security_group" "mysecurity1" {
  name        = "wpsecurity"
  description = "Allow TLS inbound traffic"
  vpc_id = aws_vpc.myvpc.id
  
  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 22
      to_port    = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wpsecurity"
  }
}

resource "aws_security_group" "mysecurity2" {
  name        = "sqlsecurity"
  description = "Allow TLS inbound traffic"
  vpc_id = aws_vpc.myvpc.id
  
  ingress {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 22
      to_port    = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sqlsecurity"
  }
}




#internet gateway
resource "aws_internet_gateway" "mygateway" {
 vpc_id = aws_vpc.myvpc.id
 tags = {
        Name = "mygateway"
}
}


#routetable
resource "aws_route_table" "myroute" {
 vpc_id = aws_vpc.myvpc.id
 tags = {
        Name = "myroute"
}
}


#internetallow
resource "aws_route" "myaccess" {
  route_table_id         = aws_route_table.myroute.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mygateway.id
}


#association
resource "aws_route_table_association" "myassociationwp" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.myroute.id
}

#instancewp
resource "aws_instance" "myinstance1" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  key_name      =  aws_key_pair.public_key.key_name
  vpc_security_group_ids = [aws_security_group.mysecurity1.id]
  subnet_id  = aws_subnet.subnet1.id
	
  tags = {
    Name = "wp"
  }
  
}

#instancesql
resource "aws_instance" "myinstance2" {
  ami           = "ami-0019ac6129392a0f2"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.public_key.key_name
  vpc_security_group_ids = [aws_security_group.mysecurity2.id]
   subnet_id  = aws_subnet.subnet2.id
	
  tags = {
    Name = "sql"
  }
}

