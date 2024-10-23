provider "aws" {
  region = "us-east-1"
}

# Tabelas DynamoDB
resource "aws_dynamodb_table" "cloudmart_products" {
  name           = "cloudmart-products"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "cloudmart_orders" {
  name           = "cloudmart-orders"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "cloudmart_tickets" {
  name           = "cloudmart-tickets"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# AMI Criando a maquina EC2 na AWS

resource "aws_instance" "ec2_instance" {
  ami           = "ami-06b21ccaeff8cd686"  # AMI Amazon Linux 2 para us-east-1
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

              # Criar pasta para descontactar o backend
              mkdir -p challenge-day2/backend && cd challenge-day2/backend

              # Baixar o arquivo cloudmart-backend.zip
              wget https://github.com/ricardolino83/terraformdocker/blob/6508e0a8676759b4de9f97ba072201b4f4e881d2/cloudmart-backend.zip

              # Descompactando o backend do sistema
              unzip cloudmart-backend.zip

              # Criar o arquivo .env do backend
              cat <<EOT >> .env
              PORT=5000
              AWS_REGION=us-east-1
              BEDROCK_AGENT_ID=<seu-bedrock-agent-id>
              BEDROCK_AGENT_ALIAS_ID=<seu-bedrock-agent-alias-id>
              OPENAI_API_KEY=<sua-chave-api-openai>
              OPENAI_ASSISTANT_ID=<seu-id-assistente-openai>
              EOT

              # Criar o arquivo Dockerfile
              cat <<EOT >> Dockerfile
              FROM node:18
              WORKDIR /usr/src/app
              COPY package*.json ./
              RUN npm install
              COPY . .
              EXPOSE 5000
              CMD ["npm", "start"]
              EOT

              # Construir e executar a imagem Docker
              docker build -t cloudmart-backend .
              docker run -d -p 5000:5000 --env-file .env cloudmart-backend

              cd ..

              # Criar pasta e baixar o código-fonte
              mkdir frontend && cd frontend
              wget https://github.com/ricardolino83/terraformdocker/blob/6508e0a8676759b4de9f97ba072201b4f4e881d2/cloudmart-frontend.zip
              unzip cloudmart-frontend.zip

              # Obter o IP público da instância
              PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

              # Criar arquivo .env do frontend
              cat <<EOT >> .env
              VITE_API_BASE_URL=http://$PUBLIC_IP:5000/api
              EOT

              #Criando o Dockerfile do frontend
              cat <<EOT >> Dockerfile
              FROM node:16-alpine as build
              WORKDIR /app
              COPY package*.json ./
              RUN npm ci
              COPY . .
              RUN npm run build

              FROM node:16-alpine
              WORKDIR /app
              RUN npm install -g serve
              COPY --from=build /app/dist /app
              ENV PORT=5001
              ENV NODE_ENV=production
              EXPOSE 5001
              CMD ["serve", "-s", ".", "-l", "5001"]
              EOT

              #Construir e executar a imagem Docker:
              docker build -t cloudmart-frontend .
              docker run -d -p 5001:5001 cloudmart-frontend

              EOF

  tags = {
    Name = "Terraform-EC2-Docker"
  }
}

# Security Group para permitir SSH, HTTP e comunicação da Backend com Frontend
resource "aws_security_group" "instance_sg" {
  vpc_id = "vpc-06f07f3a420fee5d3"
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
