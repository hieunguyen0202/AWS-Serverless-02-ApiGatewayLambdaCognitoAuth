resource "aws_lambda_function" "generate_short_url" {
  function_name = var.generate_short_url_function_name
  role          = var.lambda_execution_role_arn
  runtime       = "python3.9"
  handler       = "app.lambda_handler"

  filename         = "${path.module}/generate_short_url.zip"
  source_code_hash = filebase64sha256("${path.module}/generate_short_url.zip")

  timeout = 5
}

resource "aws_lambda_function" "get_url" {
  function_name = var.get_url_function_name
  role          = var.lambda_execution_role_arn
  runtime       = "python3.9"
  handler       = "app.lambda_handler"

  filename         = "${path.module}/get_url.zip"
  source_code_hash = filebase64sha256("${path.module}/get_url.zip")

  timeout = 5
}
