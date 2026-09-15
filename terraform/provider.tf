terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "Manara-SAA-Graduation-Project-1"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Mohamed Alksas"
    }
  }
}
