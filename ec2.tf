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

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "0.6.0"

  key_name   = var.key_name
  public_key = file(var.pub_key_location)

  tags = local.common_tags
}

#
# Mongo server
#
resource "aws_instance" "mongo_server" {
  instance_type = "t3.nano"
  ami           = data.aws_ami.ubuntu.id
  key_name      = module.key_pair.this_key_pair_key_name

  subnet_id                   = element(module.vpc.public_subnets,0)
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.ssh.id, 
    aws_security_group.mongo_server.id
  ]

  provisioner "file" {
    source      = "./FlaskWithMongoDB"
    destination = "/home/ubuntu"

    connection {
      user        = "ubuntu"
      private_key = file(var.private_key_location)
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = concat(local.docker_install_steps, [
      "cd FlaskWithMongoDB",
      "sudo docker-compose up -d mongodb"
    ])

    connection {
      user        = "ubuntu"
      private_key = file(var.private_key_location)
      host        = self.public_ip
    }
  }

  tags = merge({Name = "mongo-server"}, local.common_tags)
}

#
# App servers
#
resource "random_shuffle" "app_server_public_subnet" {
  count = var.app_server_count
  input = module.vpc.public_subnets
  result_count = 1
}

resource "aws_instance" "app_server" {
  count                       = var.app_server_count

  instance_type = "t3.nano"
  ami           = data.aws_ami.ubuntu.id
  key_name      = module.key_pair.this_key_pair_key_name

  subnet_id                   = random_shuffle.app_server_public_subnet[count.index].result[0]
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.ssh.id, 
    aws_security_group.app_server.id
  ]

  provisioner "file" {
    source      = "./FlaskWithMongoDB"
    destination = "/home/ubuntu"

    connection {
      user        = "ubuntu"
      private_key = file(var.private_key_location)
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = concat(local.docker_install_steps, [
      "cd FlaskWithMongoDB",
      "export MONGODB_URI=mongodb://${aws_instance.mongo_server.private_ip}:27017",
      "sudo -E bash -c 'docker-compose up -d app'"
    ])

    connection {
      user        = "ubuntu"
      private_key = file(var.private_key_location)
      host        = self.public_ip
    }
  }

  depends_on = [aws_instance.mongo_server]

  tags = merge({Name = "app-server-${count.index}"}, local.common_tags)
}