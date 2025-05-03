resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "API Gateway for URL shortener"
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "generate_short_url" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "generate-short-url"
}


resource "aws_api_gateway_resource" "link" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "link"
}

resource "aws_api_gateway_resource" "link_short_url" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.link.id
  path_part   = "{short_url}"
}

# POST /api/generate-short-url
resource "aws_api_gateway_method" "post_generate" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.generate_short_url.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_generate" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.generate_short_url.id
  http_method             = aws_api_gateway_method.post_generate.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.generate_lambda_invoke_arn
}

# GET /link/{short_url}
resource "aws_api_gateway_method" "get_short_url" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.link_short_url.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.short_url" = true
  }
}

resource "aws_api_gateway_integration" "get_short_url" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.link_short_url.id
  http_method             = aws_api_gateway_method.get_short_url.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.get_lambda_invoke_arn
}

# Deployment and Stage
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.post_generate,
    aws_api_gateway_integration.get_short_url
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id
  description = "Deployed at ${timestamp()}"
}

resource "aws_api_gateway_stage" "stage" {
  rest_api_id     = aws_api_gateway_rest_api.this.id
  stage_name      = var.stage_name
  deployment_id   = aws_api_gateway_deployment.deployment.id
  description     = "Stage for versioned deployment"
}
