output "main_queue_url" {
  value = aws_sqs_queue.main_queue.id
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.id
}

output "lambda_function_arn" {
  value = aws_lambda_function.trigger_lambda.arn
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.ecs_task.id
}