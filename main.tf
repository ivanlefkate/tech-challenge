terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

#
# VPC
#
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70.0"

  name                 = var.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = var.public_subnets
  enable_dns_hostnames = true

  tags = local.common_tags
}

#
# SSH key and SG
#
module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "0.6.0"

  key_name   = var.key_name
  public_key = file(var.pub_key_location)

  tags = local.common_tags
}

resource "aws_security_group" "all_hosts_ssh" {
  name   = "all-hosts-ssh"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = var.all_hosts_ssh_allowed
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
    cidr_blocks = var.app_access_allowed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

module "app_elb" {
  source  = "terraform-aws-modules/elb/aws"
  version = "2.4.0"

  name            = "app-elb"
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.app_elb.id]

  listener = [{
    lb_port           = "80"
    lb_protocol       = "HTTP"
    instance_port     = "80"
    instance_protocol = "HTTP"
  }]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  number_of_instances = var.app_host_count
  instances           = aws_instance.app_hosts.*.id

  tags = local.common_tags
}

#
# App hosts
#
data "aws_ami" "ubuntu" {
  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = [local.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "app_host" {
  name   = "app-host"
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = local.common_tags
}

resource "aws_security_group_rule" "app_host" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  source_security_group_id = module.app_elb.this_elb_source_security_group_id
  security_group_id        = aws_security_group.app_host.id
}

resource "aws_instance" "app_hosts" {
  count                       = var.app_host_count

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.nano"
  subnet_id                   = element(module.vpc.public_subnets,0)
  key_name                    = module.key_pair.this_key_pair_key_name
  vpc_security_group_ids      = [aws_security_group.all_hosts_ssh.id, aws_security_group.app_host.id]
  associate_public_ip_address = true

  tags = merge ({
      Name = "app-host-${count.index}"
    },
    local.common_tags
  )

  provisioner "file" {
    source      = "./FlaskWithMongoDB"
    destination = "/home/ubuntu"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_location)
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      # Install requirements
      "sudo apt-get update && sudo apt-get -y install docker.io",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.28.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",

      # Run app container
      "cd FlaskWithMongoDB",
      "export MONGODB_URI=mongodb://${aws_instance.mongo_host.private_ip}:27017",
      "sudo -E bash -c 'docker-compose up -d app'"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_location)
      host        = self.public_ip
    }
  }

  depends_on = [aws_instance.mongo_host]
}

#
# Mongo host
#
resource "aws_security_group" "mongo_host" {
  name   = "mongo-host"
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group_rule" "mongo_host" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 27017
  to_port   = 27017

  source_security_group_id = aws_security_group.app_host.id
  security_group_id        = aws_security_group.mongo_host.id
}

resource "aws_instance" "mongo_host" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.nano"
  subnet_id                   = element(module.vpc.public_subnets,0)
  key_name                    = module.key_pair.this_key_pair_key_name
  vpc_security_group_ids      = [aws_security_group.all_hosts_ssh.id, aws_security_group.mongo_host.id]
  associate_public_ip_address = true

  tags = merge ({
      Name = "mongo-host"
    },
    local.common_tags
  )

  provisioner "file" {
    source      = "./FlaskWithMongoDB"
    destination = "/home/ubuntu"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_location)
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      # Install requirements
      "sudo apt-get update && sudo apt-get -y install docker.io",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.28.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",

      # Run mongodb container
      "cd FlaskWithMongoDB",
      "sudo docker-compose up -d mongodb"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_location)
      host        = self.public_ip
    }
  }
}