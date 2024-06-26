variable "aws_region" {
  default = "eu-south-2"
}

variable "main_queue_name" {
  default = "mitma-queue"
}

variable "dlq_name" {
  default = "mitma-dlq"
}

variable "lambda_function_name" {
  default = "mitma-s3-load"
}

variable "ecs_cluster_name" {}
variable "ecs_task_definition" {}
variable "subnet_id" {}
variable "security_group_id" {}
variable "execution_role_arn" {}
variable "task_role_arn" {}