##### Instructions 

To create ssh new ssh keys execute:
>mkdir -p .ssh && ssh-keygen -f .ssh/id_rsa -N ""

Or especify other paths for existing ones in the terraform commands below.

To deploy the infrastructure configure AWS credentials and then execute the following commands:
>terraform init

>terraform apply -var pub_key_location=$(pwd)/.ssh/id_rsa.pub -var private_key_location=$(pwd)/.ssh/id_rsa -var app_host_count=2

Additional variables can be found in Terraform/variables.tf file.
