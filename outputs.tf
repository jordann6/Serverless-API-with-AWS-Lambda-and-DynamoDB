output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.api_lambda.arn
}

output "api_url" {
  description = "The URL of the API Gateway endpoint"
  value       = "https://${aws_api_gateway_rest_api.my_api.id}.execute-api.${var.region}.amazonaws.com/test"
}