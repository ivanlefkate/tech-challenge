output "mongo_host_public_dns" {
  value = aws_instance.mongo_host.public_dns
}

output "app_hosts_public_dns" {
  value = aws_instance.app_hosts.*.public_dns
}

output "app_elb_dns" {
  value = module.app_elb.this_elb_dns_name
}