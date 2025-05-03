output "api_stage_url" {
  value = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}/"
}

output "api_gateway_arn" {
  value = aws_api_gateway_rest_api.this.arn
}

output "api_gateway_rest_api_id" {
  value = aws_api_gateway_rest_api.this.id
}
