output "generate_short_url_function_arn" {
  value = aws_lambda_function.generate_short_url.arn
}

output "get_url_function_arn" {
  value = aws_lambda_function.get_url.arn
}
