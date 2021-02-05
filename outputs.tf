output "mongo_server_public_dns" {
  value = aws_instance.mongo_server.public_dns
}

output "app_server_public_dns" {
  value = aws_instance.app_server.*.public_dns
}

output "app_elb_dns" {
  value = module.app_elb.this_elb_dns_name
}