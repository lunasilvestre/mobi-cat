# terraform/lambda.tf
resource "aws_lambda_function" "process_sqs" {
  filename         = "function.zip"
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("function.zip")

  environment {
    variables = {
      S3_BUCKET_NAME = var.s3_bucket_name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    aws_sqs_queue.main_queue
  ]
}