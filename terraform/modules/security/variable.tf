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
