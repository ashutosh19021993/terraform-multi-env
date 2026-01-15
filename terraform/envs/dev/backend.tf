terraform {
  backend "s3" {
    bucket = "tf-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"

    # locking (new)
    use_lockfile = true

    # LocalStack endpoint (new style)
    endpoints = {
      s3 = "http://localhost:4566"
    }

    # CRITICAL: avoid tf-state.localhost DNS
    #use_path_style = true

    # LocalStack skips
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
  }
}
