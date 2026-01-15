env     = "dev"
project = "myapp"
region  = "us-east-2"

azs = ["us-east-2a", "us-east-2b"]

vpc_cidr = "10.30.0.0/16"

public_subnet_cidrs  = ["10.30.1.0/24", "10.30.2.0/24"]
private_subnet_cidrs = ["10.30.11.0/24", "10.30.12.0/24"]

ami_id        = "ami-localstack"
instance_type = "t3.small"