provider "aws" {
  region = "us-east-1"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  endpoints {
    ec2 = "http://localstack:4566"
    s3  = "http://localstack:4566"
    sts = "http://localstack:4566"
    iam = "http://localstack:4566"
  }

  s3_use_path_style = true
}