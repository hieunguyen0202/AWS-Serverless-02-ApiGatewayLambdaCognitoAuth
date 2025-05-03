output "generate_short_url_function_arn" {
  value = aws_lambda_function.generate_short_url.arn
}

output "get_url_function_arn" {
  value = aws_lambda_function.get_url.arn
}


output "generate_short_url_invoke_arn" {
  value = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.generate_short_url.arn}/invocations"
}

output "get_url_invoke_arn" {
  value = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.get_url.arn}/invocations"
}




output "generate_short_url_lambda_name" {
  value = aws_lambda_function.generate_short_url.function_name
}

output "get_url_lambda_name" {
  value = aws_lambda_function.get_url.function_name
}
