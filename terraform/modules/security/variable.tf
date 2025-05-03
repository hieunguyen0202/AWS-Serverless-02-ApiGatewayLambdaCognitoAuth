variable "role_name" {
  description = "IAM role name for Lambda function"
  type        = string
}

variable "policy_name" {
  description = "IAM policy name for accessing DynamoDB"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  type        = string
}



variable "generate_lambda_function_name" {
  type        = string
  description = "Name of the generate short URL Lambda function"
}

variable "get_lambda_function_name" {
  type        = string
  description = "Name of the get URL Lambda function"
}

variable "api_gateway_rest_api_arn" {
  type        = string
  description = "ARN of the API Gateway REST API"
}