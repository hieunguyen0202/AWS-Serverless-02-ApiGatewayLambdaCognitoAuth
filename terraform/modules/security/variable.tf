variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}


variable "aws_account_id" {
  description = "aws_account_id"
  type        = string
}


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



variable "api_gateway_rest_api_id" {
  description = "ID of the API Gateway REST API"
  type        = string
}


variable "stage_name" {
  description = "Stage name for deployment (e.g. dev)"
  type        = string
}
