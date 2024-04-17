provider "aws" {
  region = "ap-southeast-1"
  access_key = "AKIAU57BJTWBEXBGQNQW"
  secret_key = "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"

}

# VPC creation
resource "aws_vpc" "myvpc" {
  instance_tenancy = "default"
  cidr_block       = "100.100.0.0/16"
  tags = {
    Name = "Pratik-VPC"
  }
}

locals {
  VPC_Id = aws_vpc.myvpc.id
}

# Internet Gateway
resource "aws_internet_gateway" "mygw" {
  vpc_id = local.VPC_Id
  tags = {
    Name = "Pratik-VPC-IGW"
  }
}

# Route Table
resource "aws_route_table" "myroute1" {
  vpc_id = local.VPC_Id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygw.id
  }
}

# Subnet
resource "aws_subnet" "subnet_1" {
  vpc_id     = local.VPC_Id
  cidr_block = "100.100.100.0/24"
  tags = {
    Name = "Pratik-VPC-subnet-1"
  }
}

# Route table Association
resource "aws_route_table_association" "myroute_asso" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.myroute1.id
}

# Security Group with HTTP and SSH Access
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow ssh and http inbound traffic"
  vpc_id      = local.VPC_Id

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
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
    Name = "allow_ssh_http"
  }
}

# VM with user data for webserver
resource "aws_instance" "myinstance" {
  ami                         = "ami-06c4be2792f419b7b"
  instance_type               = "t2.micro"
  key_name                    = "pratik-key"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet_1.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install apache2 -y
    echo "Hello From Pratik" > /var/www/html/index.html
    sudo systemctl start apache2
    sudo systemctl enable apache2
    EOF

  tags = {
    Name = "Webserver"
  }
}

output "host_ip" {
  value = aws_instance.myinstance.public_ip
}
