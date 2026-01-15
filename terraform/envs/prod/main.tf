locals {
  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

module "ec2" {
  source = "../../../modules/ec2"

  name          = "${var.project}-${var.env}-${var.region}-app1"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_ids[0]
  ami_id        = var.ami_id
  instance_type = var.instance_type
  tags          = local.tags
}

module "vpc" {
  source = "../../../modules/vpc"

  name = "${var.project}-${var.env}-${var.region}-vpc"

  cidr = var.vpc_cidr
  azs  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  tags = local.tags
}