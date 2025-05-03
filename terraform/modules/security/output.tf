output "lambda_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.lambda_dynamodb_role.arn
}