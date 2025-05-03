variable "generate_short_url_function_name" {
  description = "Lambda function name for generating short URLs"
  type        = string
}

variable "get_url_function_name" {
  description = "Lambda function name for retrieving long URLs"
  type        = string
}

variable "lambda_execution_role_arn" {
  description = "IAM role ARN to attach to Lambda functions"
  type        = string
}
