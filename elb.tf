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

  number_of_instances = var.app_server_count
  instances           = aws_instance.app_server.*.id

  tags = local.common_tags
}