provider "aws" {
  region = var.aws_region
}

resource "aws_sqs_queue" "main_queue" {
  name = var.main_queue_name
}

resource "aws_sqs_queue" "dlq" {
  name = var.dlq_name
}

resource "aws  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
          "ecs:RunTask",
          "ecs:StopTask",
          "iam:PassRole"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_lambda_function" "trigger_lambda" {
  function_name = var.lambda_function_name
  role = aws_iam_role.lambda_execution.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.8"
  filename = data.archive_file.lambda_zip.output_path
  environment {
    variables = {
      ECS_CLUSTER_NAME    = var.ecs_cluster_name
      ECS_TASK_DEFINITION = var.ecs_task_definition
      SUBNET_ID           = var.subnet_id
      SECURITY_GROUP_ID   = var.security_group_id
    }
  }
}

resource "aws_lambda_permission" "allow_sqs_invoke" {
  statement_id = "AllowSQSTrigger"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_lambda.function_name
  principal = "sqs.amazonaws.com"
  source_arn = aws_sqs_queue.main_queue.arn
}

resource "aws_sqs_queue_policy" "main_queue_policy" {
  queue_url = aws_sqs_queue.main_queue.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "sqs.amazonaws.com"
        },
        "Action": "sqs:SendMessage",
        "Resource": aws_sqs_queue.main_queue.arn,
        "Condition": {
          "ArnEquals": {
            "aws:SourceArn": aws_sqs_queue.main_queue.arn
          }
        }
      }
    ]
  })
}

resource "aws_ecs_task_definition" "ecs_task" {
  family = "process-tar-file"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory = "1024"
  cpu = "512"
  execution_role_arn = var.execution_role_arn
  task_role_arn = var.task_role_arn

  container_definitions = jsonencode([
    {
      name: "process-tar-container",
      image: "your-account-id.dkr.ecr.your-region.amazonaws.com/process-tar-file:latest",
      essential: true,
      memory: 1024,
      cpu: 512,
      environment: [
        { name: "SQS_QUEUE_URL", value: "your-sqs-queue-url" }
      ],
      logConfiguration: {
        logDriver: "awslogs",
        options: {
          "awslogs-group" : "/ecs/process-tar-file",
          "awslogs-region" : var.aws_region,
          "awslogs-stream-prefix" : "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/process-tar-file"
  retention_in_days = 7
}