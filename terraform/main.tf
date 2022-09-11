# 命名規則は右記を参考 https://dev.classmethod.jp/articles/aws-name-rule/

provider "aws" {
  profile = "default"
  region  = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.72"
    }
  }
  required_version = ">= 1.0.0"
  backend "s3" {
    bucket = "dev.ksanchu.us-west-2"
    key    = "terraform/backend/koel"
    region = "us-west-2"
  }
}
