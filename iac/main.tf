#########################################################
# Locals Definition
#########################################################
locals {
  common_tags = {
    Environment = var.environment
    App         = "DevOps"
    Terraform   = "true"
  }
}

#########################################################
# VPC Setup
#########################################################
resource "aws_vpc" "devops_vpc" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.common_tags, { Name = "devops-vpc" })
}

#########################################################
# Subnets Setup
#########################################################
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "devops_subnets" {
  count                   = var.subnets_count
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, var.subnets_cidr_bits, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(local.common_tags, { Name = "devops-subnet${count.index + 1}" })
}

# ROUTING #
resource "aws_internet_gateway" "devops_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = merge(local.common_tags, { Name = "devops-internet-gateway" })
  depends_on = [
    aws_vpc.devops_vpc
  ]
}

resource "aws_route_table" "devops_public_rtbl" {
  vpc_id = aws_vpc.devops_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_igw.id
  }

  tags = merge(local.common_tags, { Name = "devops-public-route-table" })
}

resource "aws_route_table_association" "devops_rta" {
  count          = var.subnets_count
  subnet_id      = aws_subnet.devops_subnets[count.index].id
  route_table_id = aws_route_table.devops_public_rtbl.id
}

# SECURITY GROUP #
resource "aws_security_group" "devops_ec2_sg" {
  name        = "devops-ec2-sg"
  description = "Allow HTTP-SSH inbound traffic and all outbound traffic for EC2 instances"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    description = "HTTP access for Python API"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH access for management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "devops-ec2-sg" })
}

#########################################################
# EC2 Instances Setup
#########################################################

data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "devops_ec2_api" {
  count                  = var.subnets_count
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.devops_subnets[count.index % var.subnets_count].id
  vpc_security_group_ids = [aws_security_group.devops_ec2_sg.id]
  key_name               = var.ec2_ssh_key_name

  tags = merge(local.common_tags, { Name = "devops-ec2${count.index + 1}" })
}

#########################################################
# Application Load Balancer Setup
#########################################################

# SECURITY GROUP #
resource "aws_security_group" "devops_alb_sg" {
  name        = "devops-alb-sg"
  description = "Allow HTTP(S) inbound traffic and all outbound traffic for ALB"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "devops-alb-sg" })
}

# ALB #
resource "aws_lb" "devops_alb" {
  name               = "devops-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.devops-alb-sg.id]
  subnets            = [for subnet in aws_subnet.devops_subnets : subnet.id]

  enable_deletion_protection = true

  tags = merge(local.common_tags, { Name = "devops-alb" })
}

# Target Group #
resource "aws_lb_target_group" "devops_tg" {
  name     = "devops-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.devops_vpc.id
}

resource "aws_lb_target_group_attachment" "devops_tg_attachment" {
  target_group_arn = aws_lb_target_group.devops_tg.arn
  target_id        = aws_instance.devops_ec2_api[*].id
  port             = 5000
}


# Listeners #
resource "aws_lb_listener" "devops_http_listener" {
  load_balancer_arn = aws_lb.devops_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "devops_https_listener" {
  load_balancer_arn = aws_lb.devops_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.devops_tg.arn
  }
}