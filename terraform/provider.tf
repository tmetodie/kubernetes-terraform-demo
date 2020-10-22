terraform {
  backend "s3" {
    bucket = "tmetodie-demos"
    key    = "terraform/dev.tfstate"
    region = "eu-central-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.11.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}
