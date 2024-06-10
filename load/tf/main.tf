# terraform/main.tf
provider "aws" {
  region = var.region 
}

module "sqs" {
  source = "./sqs.tf"
}

module "iam" {
  source = "./iam.tf"
}

module "lambda" {
  source = "./lambda.tf"
}