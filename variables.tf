variable region {
  default = "us-east-1"
}

variable vpc_name {
  default = "test-stack"
}

variable vpc_cidr {
  default = "10.144.0.0/16"
} 

variable public_subnets {
  type    = list
  default = [
    "10.144.0.0/20",
    "10.144.16.0/20"
  ]
}

variable key_name {
  default = "test-stack"
}

variable pub_key_location {
  default = ""
}

variable private_key_location {
  default = ""
} 

variable app_server_count {
  default = 2
}

variable ssh_allowed {
  type    = list
  default = [ "0.0.0.0/0" ]
}

variable app_allowed {
  type    = list
  default = [ "0.0.0.0/0" ]
}