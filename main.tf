provider "aws" {
  region = "us-east-1"
}

# Criar VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

# Criar Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# Criar sub-rede pública
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "my-subnet"
  }
}

# Criar rota para a internet
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "my-route-table"
  }
}

# Associar rota à sub-rede
resource "aws_route_table_association" "my_route_table_assoc" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Security Group para permitir SSH e HTTP
resource "aws_security_group" "instance_sg" {
  vpc_id = aws_vpc.my_vpc.id
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

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5001
    to_port     = 5001
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

# AMI Criando a maquina EC2 na AWS

resource "aws_instance" "ec2_instance" {
  ami                         = "ami-06b21ccaeff8cd686"  # AMI Amazon Linux 2 para us-east-1
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.my_subnet.id  # Certifique-se de associar à sub-rede criada

  # Definindo IP público
  associate_public_ip_address = true

  # Security group para permitir acesso SSH e HTTP
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  # Script para instalar o Docker após iniciar a instância
  user_data = <<-EOF
              #!/bin/bash
              mkdir ricardolino

              EOF

  tags = {
    Name = "Terraform-EC2-Docker"
  }
}
