# AWS-Serverless-02-ApiGatewayLambdaCognitoAuth


### Architure Design
![alt text](AWS-Serverless-02-ApiGatewayLambdaCognitoAuth.drawio.svg)

### Implement step

- Step 1: Create UrlShortenTable in AWS DynamoDB
    - Option 1: Using AWS Console
        - Go to AWS DynamoDB Console
        - Click “Create table”
        - Enter the following:
            - Table name: UrlShortenTable
            - Partition key:
                - Name: short_url
                - Type: String
        - Leave the rest as default (on-demand capacity is fine for testing).
        - Click “Create table”

    - Option 2: Using AWS CLI

    ```
    aws dynamodb create-table \
        --table-name UrlShortenTable \
        --attribute-definitions AttributeName=short_url,AttributeType=S \
        --key-schema AttributeName=short_url,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region ap-southeast-1
    ```


- Step 2: Setup Lambda Function for `generate_short_url` backend
    - Select `Author from scratch`
    - Create new function with name `AWS-Serverless-02-generate-short-url-func`
    - And past the code backend from `repos/AWS-Serverless-02-shorten-link-backend/generate_short_url/app.py`
    - Choose runtime `Python 3.9`
    - Choose `Create a new role with basic Lambda permissions`
    - Click on Create Functions


- Step optional: Steps to Fix in AWS Console
    - Go to IAM > Roles in the AWS Console.
    - Search for the role mentioned in the error message: `AWS-Serverless-02-generate-short-url-func-role-5xzubgbf`
    - Click the role to open it.
    - Click `Add permissions` → `Attach policies`.
    - Choose `Create inline policy` (or update existing one).
    - Use the following policy to give access only to your table:

    ```
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem"
            ],
            "Resource": "arn:aws:dynamodb:ap-southeast-1:143735903781:table/UrlShortenTable"
            }
        ]
    }

    ```


- Step 3: Setup Lambda Function for `get_url` backend
    - Select `Author from scratch`
    - Create new function with name `AWS-Serverless-02-get-url-func`
    - And past the code backend from `repos/AWS-Serverless-02-shorten-link-backend/get_url/app.py`
    - Choose runtime `Python 3.9`
    - Choose `Create a new role with basic Lambda permissions`
    - Click on Create Functions