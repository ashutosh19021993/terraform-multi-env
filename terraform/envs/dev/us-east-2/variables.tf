variable "env"     { type = string }
variable "project" { type = string }
variable "region"  { type = string }

variable "azs"                 { type = list(string) }
variable "vpc_cidr"            { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs"{ type = list(string) }

variable "ami_id"        { type = string }
variable "instance_type" { type = string }
