variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "generate_lambda_invoke_arn" {
  description = "Invoke ARN of generate short URL Lambda"
  type        = string
}

variable "get_lambda_invoke_arn" {
  description = "Invoke ARN of get original URL Lambda"
  type        = string
}

variable "stage_name" {
  description = "Stage name for deployment (e.g. dev)"
  type        = string
}
