# terraform/sqs.tf
resource "aws_sqs_queue" "dlq" {
  name                        = var.dlq_name
  visibility_timeout_seconds  = 600
  message_retention_seconds   = 3600
}

resource "aws_sqs_queue" "main_queue" {
  name                        = var.main_queue_name
  visibility_timeout_seconds  = 600
  message_retention_seconds   = 3600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}

output "main_queue_url" {
  value = aws_sqs_queue.main_queue.url
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.url
}