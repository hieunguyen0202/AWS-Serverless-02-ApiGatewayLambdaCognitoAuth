provider "aws" {
  region = var.aws_region
}

module "dynamodb" {
  source             = "./modules/dynamodb"
  table_name         = var.table_name
  partition_key_name = var.partition_key_name
  partition_key_type = var.partition_key_type
  tags               = var.tags
}


module "lambda_func" {
  source = "./modules/lambda_func"

  generate_short_url_function_name = var.generate_short_url_function_name
  get_url_function_name            = var.get_url_function_name
  lambda_execution_role_arn        = module.security.lambda_role_arn
}

module "api_gateway" {
  source                     = "./modules/api_gateway"
  api_name                   = var.api_name
  generate_lambda_invoke_arn = module.lambda_func.generate_short_url_invoke_arn
  get_lambda_invoke_arn      = module.lambda_func.get_url_invoke_arn
  stage_name                 = var.stage_name
}

module "security" {
  source                  = "./modules/security"
  role_name               = var.lambda_role_name
  policy_name             = var.lambda_policy_name
  dynamodb_table_arn      = module.dynamodb.dynamodb_table_arn
  aws_account_id          = var.aws_account_id
  stage_name              = var.stage_name
  api_gateway_rest_api_id = module.api_gateway.api_gateway_rest_api_id


  generate_lambda_function_name = module.lambda_func.generate_short_url_lambda_name
  get_lambda_function_name      = module.lambda_func.get_url_lambda_name
  api_gateway_rest_api_arn      = module.api_gateway.api_gateway_arn

}
