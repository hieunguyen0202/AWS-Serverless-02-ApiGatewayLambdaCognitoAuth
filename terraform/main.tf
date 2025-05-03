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

module "security" {
  source             = "./modules/security"
  role_name          = var.lambda_role_name
  policy_name        = var.lambda_policy_name
  dynamodb_table_arn = module.dynamodb.dynamodb_table_arn
}


module "lambda_func" {
  source = "./modules/lambda_func"

  generate_short_url_function_name = var.generate_short_url_function_name
  get_url_function_name            = var.get_url_function_name
  lambda_execution_role_arn        = module.security.lambda_role_arn
}