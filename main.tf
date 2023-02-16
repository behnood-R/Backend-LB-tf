provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public_subnet_1" {
  cidr_block = var.public_subnet_1_cidr
  vpc_id = aws_vpc.main.id
  availability_zone = var.public_subnet_1_az
  tags = {
    Name = var.public_subnet_1_name
  }
}

resource "aws_subnet" "public_subnet_2" {
  cidr_block = var.public_subnet_2_cidr
  vpc_id = aws_vpc.main.id
  availability_zone = var.public_subnet_2_az
  tags = {
    Name = var.public_subnet_2_name
  }
}

resource "aws_security_group" "backend_server" {
  name_prefix = "backend_server"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "backend_server" {
  ami = var.backend_server_ami
  instance_type = var.backend_server_instance_type
  subnet_id = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.backend_server.id]
  key_name = var.key_name
  tags = {
    Name = var.backend_server_name
  }
}

resource "aws_lb" "lb" {
  name = var.lb_name
  internal = false
  load_balancer_type = "application"
  subnets = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups = [aws_security_group.lb.id]
}

resource "aws_security_group" "lb" {
  name_prefix = "lb"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "backend_server" {
  name = var.lb_target_group_name
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  health_check {
    path = "/"
    protocol = "HTTP"
    port = "traffic-port"
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
  }
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.lb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.backend_server.arn
  }
}

resource "aws_api_gateway_rest
