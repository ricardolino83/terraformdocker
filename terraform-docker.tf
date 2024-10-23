provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ec2_instance" {
  ami           = "ami-0c02fb55956c7d316"  # AMI Amazon Linux 2 para us-east-1
  instance_type = "t2.micro"

  # Definindo IP público
  associate_public_ip_address = true

  # Security group para permitir acesso SSH e HTTP
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  # Script para instalar o Docker após iniciar a instância
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              EOF

  tags = {
    Name = "Terraform-EC2-Docker"
  }
}

# Security Group para permitir SSH e HTTP
resource "aws_security_group" "instance_sg" {
  name        = "allow_ssh_http"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["189.79.120.2/32"]
  }

  ingress {
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
}

# Saída para mostrar o IP público da instância
output "public_ip" {
  value = aws_instance.ec2_instance.public_ip
}
