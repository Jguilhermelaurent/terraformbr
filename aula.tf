terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = " 3.74.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "Seu id da aws"
  secret_key = "Chave acesso da aws"
}

# Create a VPC
resource "aws_vpc" "vpc_brq" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc_legal"
  }
}
resource "aws_subnet" "subrede_brq" {
  vpc_id   = aws_vpc.vpc_brq.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet_legal"
  }
}

resource "aws_route_table_association" "associacao_brq" {
  subnet_id      = aws_subnet.subrede_brq.id
  route_table_id = aws_route_table.rotas_brq.id
}

resource "aws_security_group" "firewall " {
  name        = "abrir_portas"
  description = "Abrir portas 22(ssh),443(https) e 80(htpp) para aula da BRQ"
  vpc_id      = aws_vpc.vpc_brq.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]    
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "firewall brq"
  }
}

resource "aws_internet_gateway" "gw_brq"{
  vpc_id = aws_vpc.vpc_brq.id

  tags = {
    Name = "gateway_brq"
  }
}
resource "aws_route_table" "rotas_brq" {
  vpc_id = aws_vpc.vpc_brq.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_brq.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw_brq.id
  }

  tags = {
    Name = "rotas_brq"
  }
}

resource "aws_network_interface" "interface_redebrq" {
  subnet_id       = aws_subnet.subrede_brq.id
  private_ips     = ["10.0.0.51"]
  security_groups = [aws_security_group.firewall.id]
  tags = {
    Name = "interface redebrq"
  }
}
resource "aws_eip" "ip_publico_brq" {
 vpc                       = true
 network_interface         = aws_network_interface.interface_redebrq.id
 associate_with_private_ip = "10.0.1.51"
 depends_on                = [aws_internet_gateway.gw_brq]
}

# Create a instancia na  AWS
resource "aws_instance" "app_web" {
 ami               = "ami-04505e74c0741db8d"
 instance_type     = "t2.micro"
 availability_zone = "us-east-1a"
  network_interface {
   device_index         = 0
   network_interface_id = aws_network_interface.interface_redebrq.id
 }
 user_data = <<-EOF
               #! /bin/bash
               sudo apt-get update -y
               sudo apt-get install -y apache2
               sudo systemctl start apache2
               sudo systemctl enable apache2
               sudo bash -c 'echo "<h1>Criando um Serve web do site Resenha neWS</h1>"  > /var/www/html/index.html'
             EOF

  tags = {
    Name = "Serve Web brq"
  }           
}






