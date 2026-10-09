terraform {
  required_version = "~> 1.16.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "mon-super-backend-tfstate-2026"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
    key          = "startup-idp/terraform.tfstate"
  }
}

provider "aws" {
  region = "eu-west-2"
}
