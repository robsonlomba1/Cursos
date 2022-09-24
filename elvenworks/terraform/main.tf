terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 4.16" 
      }
    }

    required_version = ">= 1.1.7"
}

provider "aws" {
    region = var.region
    shared_credentials_file = ".aws/credentials"
    profile = "awsterraform"
#    access_key    = "ASIAY5O3"
#    secret_key    = "CCgCoFqjDyQS1/"
#    token         = "IQoJb3JzdGkfMDlKMDoKxnh+J4IgALTERZYG7KrbrkgqPDjmObTbrKz6ttRwR87WXhkMRx+vlAk="
 }

resource "aws_security_group" "robson-project-web" {
  name        = var.name_security_group_web
  description = "Permite acesso HTTP para app"
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks       = ["0.0.0.0/0"]
    description       = "HTTP"
    protocol          = "tcp"
    from_port         = 80
    to_port           = 80
  }

  ingress {
    cidr_blocks       = ["0.0.0.0/0"]
    description       = "SSH"
    protocol          = "tcp"
    from_port         = 22
    to_port           = 22
  }

  egress {
    cidr_blocks       = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks  = [ "::/0" ]
    from_port         = 0
    to_port           = 0
    protocol          = "-1"   
  }
  
  tags = {
    Name = "robson-project-web"
  } 
  
}

resource "aws_instance" "robson-project-app" {
  ami                         = var.ami_aws_instance
  instance_type               = var.type_aws_instance
  vpc_security_group_ids      = [aws_security_group.robson-project-web.id]
  key_name                    = var.key_aws_instance
  monitoring                  = true
  subnet_id                   = var.subnet_id_aws_instance[0]
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash		
  apt update -y && apt install curl ansible unzip git software-properties-common -y
  add-apt-repository ppa:ondrej/php -y && apt update -y

  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
    
  cd /opt && git clone https://github.com/robsonlomba1/Cursos.git && cd ./Cursos/elvenworks/ansible/
  ansible-playbook wordpress.yml

  EOF

  tags = {
    Name = "srv-robson-project-template"
  }
}

resource "aws_security_group" "robson-project-db" {
  name        = var.name_robson-project-db
  description = "Permite acesso do EC2 no RDS"
  vpc_id      = var.vpc_id

  ingress {
    security_groups = [aws_security_group.robson-project-web.id]
    description       = "Banco"
    protocol          = "tcp"
    from_port         = 3306
    to_port           = 3306
  }

  egress {
    cidr_blocks       = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks  = [ "::/0" ]
    from_port         = 0
    to_port           = 0
    protocol          = "-1"   
  }
  
  tags = {
    Name = "robson-project-db"
  } 
  
}

# RDS:
#   engine: mysql 5.7
#   user:   wpuser
#   name:   wordpress
#   pass:   Wp@12345
#   type: t2.micro
#   storage: 20Gb
#   AZ: 1a e 1b
#   Security-Group:
#       name: robson-project-db
#       porta: 3306
#       Allow: robson-project-web
#
#   Setar multiAZ

resource "aws_db_instance" "default" {
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "5.7.38"
  instance_class          = "db.t3.micro"
  db_name                 = "wordpress"
  username                = "wpuser"
  password                = "Wp-123@mudar"
 # db_subnet_group_name    = var.subnet_id_aws_instance[0]
  parameter_group_name    = "default.mysql5.7"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.robson-project-db.id]
  multi_az                = false
#  availability_zone       = var.availability_zones[0]
}

# ElastiCache:
#   Security-Group
#       name: robson-project-sessoes
#       allow: robson-project-web 
#       porta: 11211
#   Subnet:
#       name: cache-sessoes-robson-project
#    Cluster MemCached:
#       name: robson-project-sessoes
#       type: cache.t4g.micro
#       versao: 1.6.6
#       nós: 1
#       

resource "aws_security_group" "robson-project-sessoes" {
  name        = var.name_robson-project-sessoes
  description = "Permite acesso do EC2 no ElastiCache"
  vpc_id      = var.vpc_id

  ingress {
    security_groups = [aws_security_group.robson-project-web.id]
    description       = "ElastiCache"
    protocol          = "tcp"
    from_port         = 11211
    to_port           = 11211
  }

  egress {
    cidr_blocks       = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks  = [ "::/0" ]
    from_port         = 0
    to_port           = 0
    protocol          = "-1"   
  }
  
  tags = {
    Name = "robson-project-sessoes"
  } 
  
}

resource "aws_elasticache_cluster" "robson-project-sessoes" {
  cluster_id            = "robson-project-sessoes"
  engine                = "memcached"
  node_type             = "cache.t4g.micro"
  num_cache_nodes       = 1
  #version               = "1.6.6"
  parameter_group_name  = "default.memcached1.6"
  port                  = 11211
  availability_zone     = var.availability_zones[0]
}

# Load Balancer:
#   ALB
#   forward 80 to 443
#   health_check: info.php

resource "aws_acm_certificate" "robson-project-cert" {
  domain_name       = "robsonproject.daredelabs.com.br"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "robson-project-alb" {
  name        = var.name_robson-project-alb
  description = "Liberacoes para ALB"
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks   = ["0.0.0.0/0"]
    description   = "ALB"
    protocol      = "tcp"
    from_port     = 80
    to_port       = 80
  }

  ingress {
    cidr_blocks   = ["0.0.0.0/0"]
    description   = "ALB"
    protocol      = "tcp"
    from_port     = 443
    to_port       = 443
  }

  egress {
    cidr_blocks       = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks  = [ "::/0" ]
    from_port         = 0
    to_port           = 0
    protocol          = "-1"   
  }
  
  tags = {
    Name = "robson-project-alb"
  } 
  
}

resource "aws_lb" "robson-project-lb" {
  name               = "robson-project-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.robson-project-alb.id]
  subnets            = var.subnet_id_aws_instance
}

resource "aws_lb_listener" "robson-project-lb-listener-http" {
  load_balancer_arn = aws_lb.robson-project-lb.arn
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

resource "aws_lb_listener" "robson-project-lb-listener-https" {
  load_balancer_arn = aws_lb.robson-project-lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.robson-project-cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.robson-project-lb-target-group.arn
  }
}

resource "aws_lb_target_group" "robson-project-lb-target-group" {
  name     = "robson-project-lb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

#ASG
resource "aws_ami_from_instance" "robson-project-ami" {
  name               = "robson-project-ami"
  source_instance_id = aws_instance.robson-project-app.id
}

resource "aws_launch_configuration" "robson-project-launch-config" {
  name          = "robson-project-launch-config"
  image_id      = aws_ami_from_instance.robson-project-ami.id
  instance_type = var.type_aws_instance
}

resource "aws_autoscaling_group" "robson-project-asg" {
  name                 = "robson-project-asg"
  launch_configuration = aws_launch_configuration.robson-project-launch-config.name
  min_size             = 1
  max_size             = 2
  vpc_zone_identifier  = var.subnet_id_aws_instance

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "robson-project-asg-lb" {
  autoscaling_group_name = aws_autoscaling_group.robson-project-asg.id
# elb                    = aws_lb.robson-project-lb.id 
  alb_target_group_arn   = aws_lb_target_group.robson-project-lb-target-group.arn
  
}

#WAF
resource "aws_wafv2_web_acl" "robson-project-waf" {
  name  = "robson-project-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "metric-waf-robson-project"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "robson-project-waf-alb" {
  resource_arn = aws_lb.robson-project-lb.arn
  web_acl_arn  = aws_wafv2_web_acl.robson-project-waf.arn
}


















