# ==========================================
# 1. SQS QUEUES (MAIN & DLQ)
# ==========================================

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-dlq"
  message_retention_seconds = 1209600 # 14 Days
}

resource "aws_sqs_queue" "main_queue" {
  name                      = "${var.project_name}-main-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400 # 1 Day
  receive_wait_time_seconds = 10    # Long polling for cost optimization

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# ==========================================
# 2. AWS LAMBDA COMPUTE LAYER
# ==========================================

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam:aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_lambda_function" "processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-processor"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 15
  memory_size      = 128
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.main_queue.arn
  function_name    = aws_lambda_function.processor.arn
  batch_size       = 10 # Pulls up to 10 messages concurrently
}

# ==========================================
# 3. API GATEWAY (INGESTION LAYER)
# ==========================================

resource "aws_apigatewayv2_api" "ingest_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
}

resource "aws_iam_role" "api_gw_sqs_role" {
  name = "${var.project_name}-api-gw-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "api_gw_sqs_policy" {
  name = "${var.project_name}-api-gw-policy"
  role = aws_iam_role.api_gw_sqs_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "sqs:SendMessage"
      Effect   = "Allow"
      Resource = aws_sqs_queue.main_queue.arn
    }]
  })
}

resource "aws_apigatewayv2_integration" "sqs_integration" {
  api_id              = aws_apigatewayv2_api.ingest_api.id
  integration_type    = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"
  credentials_arn     = aws_iam_role.api_gw_sqs_role.arn

  request_parameters = {
    "QueueUrl"    = aws_sqs_queue.main_queue.url
    "MessageBody" = "$request.body"
  }
}

resource "aws_apigatewayv2_route" "post_route" {
  api_id    = aws_apigatewayv2_api.ingest_api.id
  route_key = "POST /ingest"
  target    = "integrations/${aws_apigatewayv2_integration.sqs_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.ingest_api.id
  name        = "$default"
  auto_deploy = true
}
