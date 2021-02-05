locals {  
  common_tags = {
    Stack = "test-stack"
  }

  ami_name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20210129"
  
  docker_install_steps = [
    "sudo apt-get update",
    "sudo apt-get -y install docker.io",
    "sudo curl -L \"https://github.com/docker/compose/releases/download/1.28.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
    "sudo chmod +x /usr/local/bin/docker-compose"
  ]
}