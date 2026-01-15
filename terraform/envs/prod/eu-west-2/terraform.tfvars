env     = "prod"
project = "myapp"
region  = "eu-west-2"

azs = ["eu-west-2a", "eu-west-2b"]

vpc_cidr = "10.30.0.0/16"

public_subnet_cidrs  = ["10.30.1.0/24", "10.30.2.0/24"]
private_subnet_cidrs = ["10.30.11.0/24", "10.30.12.0/24"]

ami_id        = "ami-localstack"
instance_type = "t3.small"