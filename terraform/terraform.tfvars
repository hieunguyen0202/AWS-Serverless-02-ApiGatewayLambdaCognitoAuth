## dynamodb module
table_name = "UrlShortenTable"


## security module
lambda_role_name   = "AWS-Serverless-02-generate-short-url-func-role"
lambda_policy_name = "AWS-Serverless-02-role-policy-dynamodb"



## lambda_func module
generate_short_url_function_name = "AWS-Serverless-02-generate-short-url-func"
get_url_function_name            = "AWS-Serverless-02-get-url-func"

## api_gateway module

api_name   = "AWS-Serverless-02-api-gateway"
stage_name = "dev"