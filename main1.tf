provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA6ITIQ7T6IZDTLE26"
  secret_key = "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"
}

resource "aws_vpc" "second-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.second-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "subnet-1"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.second-vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.second-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "route_table_asso" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.route_table.id
}
resource "aws_security_group" "allow-web" {
  name        = "allow-web-traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.second-vpc.id



  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
   
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}
resource "aws_instance" "ubuntu-2"  {
  ami = "ami-0149b2da6ceec4bb0"
  instance_type = "t2.medium"
  key_name = "TEST"
  associate_public_ip_address = true
  subnet_id = aws_subnet.subnet-1.id
  vpc_security_group_ids = [aws_security_group.allow-web.id]
}
output "my-public-ip"{
       value= aws_instance.ubuntu-2.public_ip
}
 
resource "null_resource" "remote-2"{
connection {
       type = "ssh"
       user = "ubuntu"
       host = aws_instance.ubuntu-2.public_ip
       private_key = file("C:/Users/AkhilReddy/Documents/terraform-projects/Project-1/TEST.pem")
       
}
provisioner "remote-exec" {
         inline = [
                      "sudo apt update",
                      "sudo apt install apt-transport-https ca-certificates curl software-properties-common -y",
                      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
                      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'",
                      "apt-cache policy docker-ce",
                      "sudo apt install docker-ce -y",
                      "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",                   
                      "sudo install minikube-linux-amd64 /usr/local/bin/minikube",
                      "sudo snap install kubectl --classic",
                      "sudo usermod -aG docker $USER && newgrp docker"
          ]

}
}