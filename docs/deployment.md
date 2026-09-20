# Deployment Guide

## 1. Project Overview

This project is a highly available event-driven e-commerce platform built on AWS.

The application uses Amazon ECS Fargate for the order API and asynchronous AWS services for order processing and customer notification.

## 2. AWS Region

The development environment is deployed in:

`ap-south-1` — Mumbai

## 3. Prerequisites

The following tools are required:

- AWS CLI
- Terraform
- Docker
- Git
- Python 3.11+

AWS authentication should use an IAM role or another approved authentication mechanism.

Do not store AWS access keys, secret keys, passwords, or temporary credentials in the repository.

## 4. Application Architecture

The request flow is:

Internet
  |
  v
Application Load Balancer
  |
  v
ECS Fargate
  |
  v
Amazon SQS
  |
  v
Lambda - Process Order
  |
  v
Amazon SNS
  |
  v
Lambda - Send Notification
  |
  v
Amazon SES
  |
  v
Customer Email

CloudWatch monitors ECS, ALB, and SQS.

SQS uses a Dead Letter Queue for failed messages.

ECS Service Auto Scaling maintains between 2 and 4 tasks based on CPU utilization.

## 5. Clone the Repository

Clone the GitHub repository:

```bash
git clone https://github.com/shankar0797/aws-event-driven-ecommerce-platform.git
```

Then enter the project directory:

```bash
cd aws-event-driven-ecommerce-platform
```

## 6. Build the Docker Image

Build the Docker image:

```bash
docker build -t ecommerce-order-api:1.1 .
```

Verify the Docker image:

```bash
docker images
```

The image should appear with the following name and tag:

```text
ecommerce-order-api:1.1
```
## 7. Push the Image to Amazon ECR

Authenticate Docker with Amazon ECR:

```bash
aws ecr get-login-password --region ap-south-1 | \
docker login --username AWS --password-stdin \
<aws-account-id>.dkr.ecr.ap-south-1.amazonaws.com
```

Tag the Docker image:

```bash
docker tag ecommerce-order-api:1.1 \
<aws-account-id>.dkr.ecr.ap-south-1.amazonaws.com/ecommerce-dev-order-api:1.1
```

Push the image to Amazon ECR:

```bash
docker push \
<aws-account-id>.dkr.ecr.ap-south-1.amazonaws.com/ecommerce-dev-order-api:1.1
```

> Replace `<aws-account-id>` with your AWS account ID when running these commands. Do not commit AWS credentials or secrets to the repository.


## 8. Initialize Terraform

Move to the development Terraform environment:

```bash
cd terraform/environments/dev
```

Initialize Terraform:

```bash
terraform init
```

Terraform will initialize the required providers and modules.

## 9. Validate Terraform

Format the Terraform configuration:

```bash
terraform fmt -recursive
```

Validate the configuration:

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

## 10. Review the Terraform Plan

Run:

```bash
terraform plan
```

Review the planned resource changes before applying them.

## 11. Deploy Infrastructure

Apply the Terraform configuration:

```bash
terraform apply
```

Review the Terraform plan and confirm the deployment when prompted.

## 12. View Terraform Outputs

After deployment, view the Terraform outputs:

```bash
terraform output
```

Important outputs include:

- ALB DNS name
- ECR repository URL
- ECS security group
- VPC ID
- SQS queue URL
- SQS DLQ URL
- SNS topic ARN
- Lambda function names

## 13. Test the Application

Get the Application Load Balancer DNS name:

```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
```

Test the health endpoint:

```bash
curl -i http://$ALB_DNS/health
```

Expected response:

```json
{
  "status": "healthy",
  "service": "order-api"
}
```

A successful HTTP 200 response confirms that the ALB can reach the ECS application.

## 14. Create an Order

Send an order through the Application Load Balancer:

```bash
curl -X POST "http://$ALB_DNS/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_name": "Customer",
    "customer_email": "verified@example.com",
    "product": "Laptop",
    "quantity": 1
  }'
```

The API generates an order ID and places the order event into Amazon SQS.

The order then continues through the asynchronous processing workflow:

ECS
  |
  v
SQS
  |
  v
Lambda - Process Order
  |
  v
SNS
  |
  v
Lambda - Send Notification
  |
  v
SES
  |
  v
Customer Email


## 15. Verify SQS Processing

Check the order queue:

```bash
aws sqs get-queue-attributes \
  --queue-url <queue-url> \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
  --region ap-south-1
```

After successful processing, the queue should return to zero visible messages.

The order message is consumed by the order-processing Lambda.

## 16. Verify Lambda Processing

Check the order-processing Lambda logs:

```bash
aws logs tail /aws/lambda/ecommerce-dev-process-order \
  --region ap-south-1 \
  --since 10m
```

The logs should show that the order was received from SQS and published to SNS.

Check the notification Lambda:

```bash
aws logs tail /aws/lambda/ecommerce-dev-send-notification \
  --region ap-south-1 \
  --since 10m
```

The logs should show successful email processing.

The complete asynchronous workflow is:

```text
SQS
 |
 v
Lambda - Process Order
 |
 v
SNS
 |
 v
Lambda - Send Notification
 |
 v
SES
 |
 v
Customer Email
```

## 17. Verify SES

The notification Lambda uses Amazon SES to send the order confirmation email.

For SES sandbox environments:

- The sender identity must be verified.
- The recipient may also need to be verified.
- Production access may be required for unrestricted sending.

Check the SES identity configuration and Lambda logs if an email is not received.

## 18. Monitoring

CloudWatch alarms are configured for the following components.

### ECS CPU

Alarm:

`ecommerce-ecs-cpu-high`

Threshold:

`CPU > 80%`

The alarm monitors average ECS service CPU utilization.

### ALB 5xx Errors

Alarm:

`ecommerce-alb-5xx`

Threshold:

`5 or more target 5xx responses`

The alarm monitors HTTP 5xx responses returned by the ALB targets.

### SQS Backlog

Alarm:

`ecommerce-sqs-backlog`

Threshold:

`10 or more visible messages`

The alarm monitors the number of visible messages waiting in the order queue.

## 19. ECS Auto Scaling

The ECS service uses target tracking based on average CPU utilization.

Configuration:

- Minimum tasks: 2
- Maximum tasks: 4
- Target CPU utilization: 60%
- Scale-out cooldown: 60 seconds
- Scale-in cooldown: 120 seconds

This allows the ECS service to increase or decrease the number of running tasks based on workload.

## 20. Dead Letter Queue

The SQS order queue is configured with a Dead Letter Queue (DLQ).

Messages that repeatedly fail processing are moved to the DLQ after the configured maximum receive count.

The project includes a tested DLQ failure scenario.

The DLQ provides a location for investigating failed messages without continuously retrying them in the main queue.


## 21. CloudFront

Terraform configuration for CloudFront is included in the repository.

However, the CloudFront distribution is currently pending AWS account verification.

The active development environment therefore uses:

```text
Internet
   |
   v
Application Load Balancer
   |
   v
ECS Fargate
```

CloudFront remains available in the Terraform module for future deployment after AWS account verification.

## 22. Destroy Development Resources

When the development environment is no longer required, move to the Terraform environment:

```bash
cd ~/aws-event-driven-ecommerce-platform/terraform/environments/dev
```

Review the resources that will be removed:

```bash
terraform plan -destroy
```

If you intentionally want to remove the development infrastructure:

```bash
terraform destroy
```

Review the Terraform plan carefully before confirming the destruction.

## 23. Security Practices

The project follows these security practices:

- IAM roles are used instead of hard-coded AWS credentials.
- IAM permissions are scoped to project resources where practical.
- ECS tasks run in private subnets.
- The Application Load Balancer is internet-facing.
- SQS provides asynchronous decoupling.
- SQS DLQ handles repeatedly failed messages.
- AWS credentials and secrets must not be committed to Git.
- Terraform state files are excluded from Git.
- Generated Terraform plan files are excluded from Git.
- Generated Lambda ZIP files are excluded from Git.


