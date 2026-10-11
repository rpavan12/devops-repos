#EC2 instance with devops ami redhat 9 with password and without key pair

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "type" {
  description = "The type of EC2 instance to create"
  type        = string
  default     = "t3.micro"
}

resource "aws_security_group" "my_security_group" {
  name        = "my-security-group"
  description = "Allow SSH and HTTP access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my_instance" {
  ami             = "ami-0220d79f3f480ecf5" # devops practice ami redhat 9 
  instance_type   = var.type
  security_groups = [aws_security_group.my_security_group.name]

  tags = {
    Name = "my-instance"
  }
}

output "instance_id" {
  description = "The ID of the created EC2 instance"
  value = {
    id         = aws_instance.my_instance.id
    private_ip = aws_instance.my_instance.private_ip
    public_ip  = aws_instance.my_instance.public_ip
  }
}