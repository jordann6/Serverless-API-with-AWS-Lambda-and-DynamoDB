# Step 1: Configure AWS Provider
provider "aws" {
  region = var.region
}

# Step 2: Define the IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Step 3: Define the IAM Policy for Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "Policy to allow Lambda execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "logs:*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Step 4: Attach the IAM Policy to the Role
resource "aws_iam_role_policy_attachment" "lambda_exec_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Step 5: Create the Lambda Function
resource "aws_lambda_function" "api_lambda" {
  function_name = "api_lambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.8"
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

# Step 6: Create the API Gateway API (rest_api)
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "my-api"
  description = "API to trigger Lambda function"
}

# Step 7: Create API Gateway Resource (Test Resource)
resource "aws_api_gateway_resource" "test_resource" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "test"
}

# Step 8: Create HTTP Method (GET)
resource "aws_api_gateway_method" "test_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.test_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Step 9: Set Up API Gateway Integration with Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.test_resource.id
  http_method             = aws_api_gateway_method.test_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.api_lambda.arn}/invocations"
}

# Step 10: Add Permissions for API Gateway to Invoke Lambda
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

# Step 11: Create API Gateway Deployment
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
}

# Step 12: Create API Gateway Stage
resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}