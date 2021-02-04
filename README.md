##### Instructions 

NOTE: For convenience, this example will create its own VPC, its name and CIDRs can be found in variables.tf file and can also be changed on the fly using the "-var" argument of terraform command.

To create new ssh keys execute:
>mkdir -p .ssh && ssh-keygen -f .ssh/id_rsa -N ""

Or especify other paths for existing ones in the terraform commands below.

To deploy the infrastructure configure AWS credentials and then execute the following commands:
>terraform init

>terraform apply -var pub_key_location=$(pwd)/.ssh/id_rsa.pub -var private_key_location=$(pwd)/.ssh/id_rsa -var app_host_count=2

Additional variables can be found in Terraform/variables.tf file.

To retrieve public dns for LB (where you can point the browser to use the web application) and instances public dns run:
>terraform output

You can ssh to instances using the ssh key used to apply the project and "ubuntu" user, eg:
>ssh -i .ssh/id_rsa ubuntu@ec2-3-231-60-18.compute-1.amazonaws.com

Number of app servers can be modified by changing the value of "app_host_count" variable:
>terraform apply -var pub_key_location=$(pwd)/.ssh/id_rsa.pub -var private_key_location=$(pwd)/.ssh/id_rsa -var app_host_count=3

If you you need to replace the ssh key, please remember to taint the instances so that they are recreated with the new key
>terraform taint aws_instance.mongo_host

>terraform taint aws_instance.app_hosts[0]

>terraform taint aws_instance.app_hosts[1]

>terraform taint aws_instance.app_hosts[3]

Then you can recreate:
>mkdir -p .ssh && ssh-keygen -f .ssh/id_rsa -N ""

>terraform apply -var pub_key_location=$(pwd)/.ssh/id_rsa.pub -var private_key_location=$(pwd)/.ssh/id_rsa -var app_host_count=2
