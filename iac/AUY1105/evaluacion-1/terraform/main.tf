terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name        = "AUY1105-miapp-vpc"
    Environment = "dev"
  }
}

# Subred
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.1.0/24"
  tags = {
    Name        = "AUY1105-miapp-subnet"
    Environment = "dev"
  }
}

# Security Group
resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "AUY1105-miapp-sg"
    Environment = "dev"
  }
}

# EC2
resource "aws_instance" "main" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main.id

  vpc_security_group_ids = [aws_security_group.main.id]

  tags = {
    Name        = "AUY1105-miapp-ec2"
    Environment = "dev"
  }
}
