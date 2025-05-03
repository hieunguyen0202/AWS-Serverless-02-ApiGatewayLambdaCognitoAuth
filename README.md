## URL Shortener Platform - AWS Architecture Documentation

### Architure Design
![alt text](AWS-Serverless-02-ApiGatewayLambdaCognitoAuth.drawio.svg)


### Overview Project

- The project include 2 parts
    - Frontend: 
        - The frontend for the URL shortener application is designed to interact with a backend deployed on AWS services such as API Gateway and Lambda. The frontend is built using modern JavaScript tooling and can be tested locally or deployed globally using S3 + CloudFront.
    - Backend:
        - Backend application responsible for generating a shortened link from a given URL.
        - Tech stack used: API Gateway, AWS Lambda, DynamoDB.
        - API structure:
            - `/api/generate-short-url`: receives a URL and returns a shortened ID for that URL.
            - `/link/<id>` where id is the shortened code of the original link. This endpoint searches for the ID in the DynamoDB table; if a match is found, it returns the original URL and redirects the user’s browser to that link.



### What you had learned after this project

#### CloudFront (CDN & Edge Caching)
- Purpose:
    - Distribute content globally with low latency.
    - Cache static and dynamic content close to the user.

- Key Actions:
    - Cache Invalidation:
        - Use AWS CLI or API:

        ```
        aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"

        ```
    - Testing Cache:
        - Use tools like curl or browser dev tools.
        - Deploy test `Lambda@Edge functions` to simulate cache behavior per region.


#### AWS Certificate Manager (ACM)
- Purpose:
    - Issue free public SSL/TLS certificates.
    - Secure communication over HTTPS.

- How to:
    - Request certificate:
        - Go to ACM → Request Certificate → Public → Add domain (e.g., *.yourdomain.com).
        - Validate via DNS.
    - Attach to CloudFront:
        - In CloudFront → Select distribution → Edit → Attach ACM cert (must be in us-east-1).


#### S3 + CloudFront (Static Web Hosting)
- Purpose: 
    - Host static web assets like HTML, CSS, JS.
    - Deliver them globally via CloudFront.
- Steps:
    - Enable static website hosting on S3.
    - Upload files:

        ```
        aws s3 sync ./static-site s3://your-bucket-name
        ```

    - Set CloudFront origin to the S3 bucket.
    - Enable OAI (Origin Access Identity) for secure access.

#### Lambda + API Gateway + Cognito
- Purpose:
    - Handle API requests.
    - Secure with Cognito authentication.
    - Token-based access control.
- API Auth Flow:
    - User authenticates via Amazon Cognito.
    - Gets ID/Access token (JWT).
    - Sends token in Authorization header to API Gateway.
    - API Gateway validates token.
    - Routes request to Lambda function.
- Token Refresh:
    - Use Cognito's hosted UI or SDKs to auto-refresh tokens.
    - Frontend stores and refreshes using refresh tokens periodically.



#### ECS (Blue/Green Deployment via ALB)

- Purpose:
    - Host different frontend versions (blue/green).
    - Seamlessly switch between versions.

- Steps:
    - Setup ALB with target groups: one for blue, one for green.
    - Attach ECS services to target groups.
    - Use API Gateway HTTP integration to point to ALB.
    - Shift traffic between versions using weighted rules or deploy pipeline.


#### CloudWatch Monitoring
- Centralized Logging
    - Lambda Logs: Automatically captures logs from AWS Lambda executions (e.g., request traces, errors, performance).
    - API Gateway Logs: Stores detailed access logs, including IPs, user agents, and HTTP status codes.
    - ECS Logs: Collects container logs (stdout/stderr) from your blue/green frontend deployments.
    - Logs:
        - Enable logging in:
            - Lambda → Monitor tab.
            - API Gateway → Enable CloudWatch Logs.

- Real-Time Monitoring & Dashboards
    - API request count
    - Error rates (4xx/5xx)
    - Lambda invocation duration
    - ECS CPU/memory usage
    - Visualize metrics with custom CloudWatch dashboards.

- Alerting and Notifications
    - Send alerts via Amazon SNS (email, SMS, or Slack).

- Export Logs to S3:
    - Create a log group subscription filter.
    - Use Kinesis Firehose → S3 or AWS Lambda → S3.
    - Create alarm → Set threshold → Notify via Amazon SNS.

- EventBridge Integration:
    - Rule: Detect S3 PutObject (i.e., static file changed).
    - Target: SNS Topic to notify users.

#### Terraform Automation

- Automate all infrastructure as code.
- Structure:

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── modules/
│   ├── api_gateway/
│   ├── ecs/
│   ├── cognito/
│   ├── cloudfront/
│   └── s3/

```

#### CI/CD with GitHub Actions

- Workflow Example (.github/workflows/deploy.yml):

```
name: Deploy to AWS

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Terraform Init & Apply
      run: |
        cd terraform
        terraform init
        terraform apply -auto-approve

    - name: Deploy Static Files to S3
      run: aws s3 sync ./static-site s3://your-bucket-name --delete


```


### Implement step

#### Part 1: Manual Setup stack Lambda + API Gateway + Cognito

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


- Step 4: How to test API works
    - A client makes a POST request to /api/generate-short-url with a body like:

        ```
        {
        "url": "https://www.example.com/very-long-article"
        }

        ```

    - The response will be something like:

        ```
        {
        "short_url_code": "A1b2C3d4E5f6G7h"
        }

        ```

#### Part 2: Auto Setup stack Lambda + API Gateway + Cognito with terraform


