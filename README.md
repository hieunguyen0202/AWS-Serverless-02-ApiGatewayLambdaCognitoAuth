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


- Step 2: Create role for Lambda Func with DynamoDB
    - Go to IAM > Roles in the AWS Console.
    - Search for the role mentioned in the error message: `AWS-Serverless-02-generate-short-url-func-role`
    - Click the role to open it.
    - Click `Add permissions` → `Attach policies`.
    - Choose `Create inline policy` (or update existing one) with name `AWS-Serverless-02-role-policy-dynamodb`.
    - Use the following policy to give access only to your table:

    ```
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:GetItem"
            ],
            "Resource": "arn:aws:dynamodb:ap-southeast-1:143735903781:table/UrlShortenTable" -> Change depend output from step 1
            }
        ]
    }

    ```


- Step 3: Setup Lambda Function for `generate_short_url` backend
    - Select `Author from scratch`
    - Create new function with name `AWS-Serverless-02-generate-short-url-func`
    - And past the code backend from `repos/AWS-Serverless-02-shorten-link-backend/generate_short_url/app.py`
    - Choose runtime `Python 3.9`
    - Choose existing role `AWS-Serverless-02-generate-short-url-func-role`
    - Click on Create Functions


- Step 4: Setup Lambda Function for `get_url` backend
    - Select `Author from scratch`
    - Create new function with name `AWS-Serverless-02-get-url-func`
    - And past the code backend from `repos/AWS-Serverless-02-shorten-link-backend/get_url/app.py`
    - Choose runtime `Python 3.9`
    - Choose existing role `AWS-Serverless-02-generate-short-url-func-role`
    - Click on Create Functions


#### Part 2: Step-by-Step Guide: API Gateway → Lambda Integration on Stage dev

- Step 1: Create or Use an Existing API
    - Go to API Gateway in AWS Console.
    - Choose or create a REST API (with name `AWS-Serverless-02-api-gateway`).

- Step 2: Create Resources and Methods
    - Create a resource like `/api` and `/link` under `/` .
    - Under that resource, add:
        - POST `/api/generate-short-url`
        - GET `/link/{short_url}`
    - To do this:
        - Select the resource (e.g., /api)
        - Click “Create Method” → choose POST
        - Select Integration type = Lambda Function.
        - Enable Lambda Proxy Integration.
        - Enter the Lambda function name `AWS-Serverless-02-generate-short-url-func` and click Save.
        - Grant permissions when prompted.
        - Repeat the above for the GET /link/{short_url} endpoint with the other Lambda function `AWS-Serverless-02-get-url-func`.

- Step 3: Deploy to a Stage (e.g., dev)
    - Click the “Actions” dropdown at the top.
    - Select Deploy API.
    - Choose:
        - Deployment stage: `dev` (or create one if not exists)
        - Stage name: `dev`
        - (Optional) Add stage description `dev_version{1/2/3...}`
    - Click Deploy.
    - Your API will now be accessible at a URL like:

    ```
    https://<api-id>.execute-api.<region>.amazonaws.com/dev/api/generate-short-url
    
    ```


#### Part 3: How to test API works

- A client makes a POST request to /api/generate-short-url with a body like:
        
    ```
        Using PortMAN

        https://ld05bg8x46.execute-api.ap-southeast-1.amazonaws.com/dev/api/generate-short-url
        
    ```
- With body
        
    ```
        {
            "url": "https://dantri.com.vn/xa-hoi/cuu-giam-doc-cong-an-hai-phong-do-huu-ca-va-ong-pham-xuan-thang-duoc-dac-xa-20250429160106555.htm"
        }

    ```

- The response will be something like:

    ```
        {
            "short_url_code": "3Olih97ScYdpNg4"
        }

    ```
- User opens a shortened link like:

    ```
        https://ld05bg8x46.execute-api.ap-southeast-1.amazonaws.com/dev/link/3Olih97ScYdpNg4
        
    ```
- The API Gateway routes /link/{short_url} to this Lambda.
- Lambda looks up `3Olih97ScYdpNg4` in DynamoDB. If it exists, the user is redirected (HTTP 308) to the original long URL:

    ```
        https://dantri.com.vn/xa-hoi/cuu-giam-doc-cong-an-hai-phong-do-huu-ca-va-ong-pham-xuan-thang-duoc-dac-xa-20250429160106555.htm
        
    ```

#### Part 4: Auto Setup stack Lambda + API Gateway + Cognito with Terraform

- Note: please execute this script `build_lambda_zips.sh` to create zip packages for deploying Lambda Func without error
- Run these command to auotmate deploy IaC
    - `cd terraform`
    - `terraform init`
    - `terraform validate`
    - `terraform plan`
    - `terraform apply`


#### Part 5: Deploy Front-end to S3 + CloudFront + AWS Certificate Manager

##### Cách triển khai chạy test ở máy Local.
1. Deploy backend stack  
Backend stack at repository: `https://github.com/hieunguyen0202/AWS-Serverless-02-shorten-link-frontend.git`
2. Copy all contents in `vite.config-local.js` override to `vite.config.js`  
*Mục đích để tạo proxy từ local lên API Gateway tránh lỗi CORS error.

3. Trong file `.env` Thay thế `VITE_BASE_URL` thành URL của API Gateway Stage (bao gồm cả stage name vd `dev`)
* vd: `https://y7acktc4xh.execute-api.ap-southeast-1.amazonaws.com/dev`
3. Start server local:
* `npm install`
* `npm run dev`
* Truy cập thông qua `localhost:<port>`
4. Test thử với một URL bất kỳ (vd trang tin tức có url dài). Kết quả trả về link rút gọn, nhấn nút copy to clipboard.
5. Truy cập thông qua link rút gọn.

##### Cách triển khai lên S3 + CloudFront

1. Deploy backend stack  
* Backend stack có tại repository: `https://github.com/hieunguyen0202/AWS-Serverless-02-shorten-link-backend.git`
* Test thử việc truy cập tạo shorten link & link sau khi tạo ra (sử dụng Postman)

2. Build Frontend project tạo ra static file  
* Copy toàn bộ nội dung trong `vite.config-aws.js` ghi đè sang `vite.config.js`
* Trong file `.env` Thay thế `VITE_BASE_URL` thành domain dự tính trỏ vào CloudFront
* vd: `https://serverless.cloudtech.io.vn`
* Chạy lệnh `npm run build`, kiểm tra thư mục dist được tạo ra.

3. Tạo một S3 bucket, Enable Static website hosting.
- bucket name vd: `aws-serverless-02-s3-web-bucket`
- Copy toàn bộ nội dung trong thư mục `dist` của project, upload lên S3.
- `cd dist`
- `aws s3 cp . s3://<your-bucket-name>/ --recursive`
- Kiểm tra các files được upload lên S3 thành công.
- Add policy sau vào s3 bucket policy:(Policy tham khảo cho S3 bucket)  
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::<your-bucket-name>/*"
        }
    ]
}
```
- Truy cập thử thông qua static url của S3, nếu hiển thị được website là OK.

4. Tạo CloudFront distribution & add S3 bucket làm origin.
* Origin domain: chọn S3 bucket ở bước trên vd: `aws-serverless-02-s3-web-bucket.s3.ap-southeast-1.amazonaws.com`
* Origin path: để trống.
* Name: đặt một tên bất kỳ vd: `aws-serverless-02-frontend-website`
* Origin access chọn: `Origin access control settings (recommended)` sau đó nhấn nút `Create new OAC`
* Enable Origin Shield chọn `No`
* Default cache behavior: 
    - Compress objects automatically chọn `No`
    - Viewer protocol policy chọn `Redirect HTTP to HTTPS`-
    - Allowed HTTP methods chọn `GET, HEAD`, Restrict viewer access chọn `No`  
    - Cache key and origin requests: Cache policy and origin request policy (recommended), Cache policy chọn `Caching Optimized`, Origin request policy không chọn, Response headers policy - optional chọn `Simple CORS`
* Web Application Firewall (WAF)  chọn không sử dụng WAF.
* Settings:
    - Price class để mặc định.
    - Alternate domain name (CNAME) - optional add một tên miền bạn dự định trỏ vào CloudFront vd: `short.hoanglinhdigital.com`
    - SSL Certificate: Chọn SSL ceritificat tương ứng (tạo sử dụng dịch vụ Certificate Manager)
    - Chọn `TLSv1.2_2021`
    - Supported HTTP versions: chọn `HTTP/2`
* Nhấn nút Create `Distribution`
* Sau khi CloudFront được tạo xong sẽ có một popup warning với nội dung: `The S3 bucket policy needs to be updated`, Click Copy policy sau đó dán vào Bucket Policy của S3.

* Chờ đợi CloudFront deploy xong sau đó truy cập thử CloudFront thông qua link vd: `https://clondfrontxxx.net/index.html` *Lưu ý phải có `index.html`

5. Thêm Origin cho API Gateway.
* Truy cập vào CloudFront vừa tạo ra ở bước trên, tab `Origin`, nhấn `Create Origin`
* Origin domain: chọn API Gateway đã tạo ra ở bước trên.
* Protocol: `HTTPS only`, Minimum Origin SSL protocol chọn `TLS 1.2`
* Origin path: `/dev`
* Name đặt tên vd: `aws-serverless-02-api-backend`
* Enable Origin Shield: `No`


6. Chỉnh sửa Behavior của CloudFront (thứ tự như bên dưới)  
* Truy cập vào CloudFront vừa tạo ra ở bước trên, tab `Behaviors`, nhấn `Create Behavior`
* Thêm Origin Behavior path `/api/*` trỏ vào API Gateway.
    - Path pattern: `/api/*`
    - Origin and origin groups: Chọn origin tương ứng với API Gateway.
    - Compress objects automatically: No
    - Viewer protocol policy: `Redirect HTTP to HTTPS`
    - Allowed HTTP methods: `GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE`
    - Restrict viewer access: No
    - Cache key and origin requests: chọn `Cache policy and origin request policy (recommended)` sau đó chọn Cache Policy: `CachingDisabled`, Origin request policy - optional chọn `AllViewerExceptHostHeader` 
    - Response headers policy - optional chọn `Simple CORS`
    - Nhấn `Create Behavior`
    - Sử dụng postman call đến API: `https://cloudfrontxxx.net/api/generate-short-url` xem có tạo được link rút gọn không?

* Thêm Origin Behavior path `/link/*` trỏ vào API Gateway.
    - Path pattern: `/link/*`
    - Origin and origin groups: Chọn origin tương ứng với API Gateway.
    - Compress objects automatically: No
    - Viewer protocol policy: `Redirect HTTP to HTTPS`
    - Allowed HTTP methods: `GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE`
    - Restrict viewer access: No
    - Cache key and origin requests: chọn `Cache policy and origin request policy (recommended)` sau đó chọn Cache Policy: `CachingDisabled`, Origin request policy - optional chọn `AllViewerExceptHostHeader` 
    - Response headers policy - optional chọn `Simple CORS`
    - Nhấn `Create Behavior`
    - Tạo một link rút gọn sử dụng link `https://cloudfrontxxx.net/api/generate-short-url`
    - Truy cập thử CloudFront thông qua link vd: `https://cloudfrontxxx.net/link/<link-id>` xem có redirect sang trang web gốc không.

7. Tạo một CNAME record trên Route53 trỏ vào CloudFront vd `short.hoanglinhdigital.com`
* Các bạn có thể sử dụng Route53 hoặc bất kỳ nhà cung cấp nào khác.

8. Test việc truy cập.
* Truy cập domain đã setting vd: `https://short.hoanglinhdigital.com/index.html` *Lưu ý phải có `/index.html` ở cuối.
* Sử dụng một URL dài (vd trang tin tức), thử tạo link rút gọn.
* Kết quả trả về link rút gọn, nhấn nút Copy sau đó truy cập thử = link rút gọn.