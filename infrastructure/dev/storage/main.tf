terraform {
  required_version = "<= 0.13.2"

  backend "s3" {
    key = "dev/storage/terraform.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region = var.region
  version = "~> 3.5.0"
}

module "storage" {
  source = "../../modules/storage"
  name = "${var.service_name}-${var.environment}"
}