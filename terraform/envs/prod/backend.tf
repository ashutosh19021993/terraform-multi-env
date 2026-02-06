terraform {
  backend "s3" {
    bucket = "tf-state-252850512189"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"

    # Recommended in real AWS
    encrypt = true
    # dynamodb_table = "terraform-locks"   # optional, recommended
  }
}
