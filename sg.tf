#
# SSH
#
resource "aws_security_group" "ssh" {
  name   = "ssh"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = var.ssh_allowed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

#
# ELB
#
resource "aws_security_group" "app_elb" {
  name   = "app-elb"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = var.app_allowed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

#
# App servers
#
resource "aws_security_group" "app_server" {
  name   = "app-server"
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = local.common_tags
}

resource "aws_security_group_rule" "app_server" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  source_security_group_id = aws_security_group.app_elb.id
  security_group_id        = aws_security_group.app_server.id
}

#
# Mongo server
#
resource "aws_security_group" "mongo_server" {
  name   = "mongo-server"
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group_rule" "mongo_server" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 27017
  to_port   = 27017

  source_security_group_id = aws_security_group.app_server.id
  security_group_id        = aws_security_group.mongo_server.id
}