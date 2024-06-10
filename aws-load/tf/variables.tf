# terraform/variables.tf
variable "region" {
  description = "AWS Region"
  type        = string
}

variable "lambda_function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "main_queue_name" {
  description = "The name of the Main SQS queue"
  type        = string
}

variable "dlq_name" {
  description = "The name of the Dead-Letter SQS queue"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "s3_key_prefix" {
  description = "The prefix for the S3 keys"
  type        = string
}