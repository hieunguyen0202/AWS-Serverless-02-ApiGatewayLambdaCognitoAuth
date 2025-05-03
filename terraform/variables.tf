variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

## dynamodb module

variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "partition_key_name" {
  description = "Partition key name"
  type        = string
  default     = "short_url"
}

variable "partition_key_type" {
  description = "Partition key type"
  type        = string
  default     = "S"
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "url-shortener"
  }
}


## security module

variable "lambda_role_name" {
  description = "IAM role name for Lambda function"
  type        = string
}

variable "lambda_policy_name" {
  description = "IAM policy name for Lambda access to DynamoDB"
  type        = string
}


## lambda_func module
variable "generate_short_url_function_name" {
  type        = string
  description = "Lambda function name for short URL generation"
}

variable "get_url_function_name" {
  type        = string
  description = "Lambda function name for retrieving original URL"
}
