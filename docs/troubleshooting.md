# Troubleshooting Guide

This document contains common issues encountered while deploying and operating the AWS Event-Driven E-Commerce Platform.

The troubleshooting approach is:

1. Identify the failing component.
2. Check its current status.
3. Review logs and AWS resource configuration.
4. Identify the root cause.
5. Apply the smallest required fix.
6. Re-test the complete flow.

---

## 1. ECS Tasks Are Not Running

### Symptoms

The ECS service shows:

```text
Desired count: 2
Running count: 0
```

### Checks

Check the ECS service:

```bash
aws ecs describe-services \
  --cluster ecommerce-dev-cluster \
  --services ecommerce-dev-order-api \
  --region ap-south-1 \
  --profile ecommerce
```

Check recent ECS stopped tasks:

```bash
aws ecs list-tasks \
  --cluster ecommerce-dev-cluster \
  --desired-status STOPPED \
  --region ap-south-1 \
  --profile ecommerce
```

Then inspect a stopped task:

```bash
aws ecs describe-tasks \
  --cluster ecommerce-dev-cluster \
  --tasks <task-arn> \
  --region ap-south-1 \
  --profile ecommerce
```

### Common Causes

- Invalid container image
- Incorrect ECS execution role
- Incorrect task definition
- Container startup failure
- Incorrect environment variables
- Insufficient IAM permissions
- Security group configuration problems

---

## 2. ALB Target Shows Unhealthy

### Symptoms

The ECS task is running, but the Application Load Balancer reports:

```text
Target: unhealthy
```

### Check Target Health

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region ap-south-1 \
  --profile ecommerce
```

### Verify Application Port

The FastAPI application listens on:

```text
Port: 8000
```

The ALB target group also forwards traffic to:

```text
Port: 8000
```

### Verify Health Endpoint

The application exposes:

```text
GET /health
```

Expected response:

```json
{
  "status": "healthy",
  "service": "order-api"
}
```

### Common Causes

- Application is not listening on port 8000
- Incorrect container port mapping
- ALB target group configured with the wrong port
- ECS security group does not allow traffic from the ALB security group
- Application failed during startup

---

## 3. `/orders` Returns HTTP 503

### Symptoms

The health endpoint works, but creating an order returns:

```text
503 Service Unavailable
```

### Check

The application requires:

```text
SQS_QUEUE_URL
```

Check the ECS task definition environment variables:

```bash
aws ecs describe-task-definition \
  --task-definition ecommerce-dev-order-api \
  --region ap-south-1 \
  --profile ecommerce
```

The task should contain:

```text
AWS_REGION=ap-south-1
SQS_QUEUE_URL=<SQS queue URL>
```

### Root Cause

The application returns HTTP 503 when it cannot send the order message to SQS.

### Application Behavior

The API catches the SQS error and returns:

```text
Unable to queue order for processing
```

### Resolution

Verify:

- `SQS_QUEUE_URL` is configured.
- ECS task role has `sqs:SendMessage`.
- The SQS queue exists.
- The application is using the correct AWS region.

---

## 4. Order Remains in SQS

### Symptoms

An order is created successfully, but the SQS queue continues to contain messages.

### Check Queue

```bash
aws sqs get-queue-attributes \
  --queue-url <queue-url> \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
  --region ap-south-1 \
  --profile ecommerce
```

### Expected Normal State

After successful processing:

```text
ApproximateNumberOfMessages: 0
ApproximateNumberOfMessagesNotVisible: 0
```

### Check Lambda

```bash
aws logs tail /aws/lambda/ecommerce-dev-process-order \
  --region ap-south-1 \
  --since 10m \
  --profile ecommerce
```

### Common Causes

- Lambda is disabled
- Event source mapping is disabled
- Lambda execution role lacks SQS permissions
- Lambda cannot publish to SNS
- Lambda is repeatedly failing

---

## 5. Process Order Lambda Is Failing

### Symptoms

Messages remain in the SQS queue or eventually move to the DLQ.

### Check Logs

```bash
aws logs tail /aws/lambda/ecommerce-dev-process-order \
  --region ap-south-1 \
  --since 10m \
  --profile ecommerce
```

### Expected Flow

```text
SQS
 |
 v
process-order Lambda
 |
 v
SNS
```

The Lambda requires:

```text
SNS_TOPIC_ARN
```

### Common Causes

- Missing `SNS_TOPIC_ARN`
- Incorrect SNS topic ARN
- Lambda IAM role does not allow `sns:Publish`
- Invalid SQS message payload
- Runtime error in Lambda code

---

## 6. Messages Move to the Dead Letter Queue

### Symptoms

Messages appear in:

```text
ecommerce-dev-order-dlq
```

### Meaning

The same SQS message failed processing repeatedly and exceeded the configured maximum receive count.

The project uses a maximum receive count of:

```text
3
```

### Check DLQ

```bash
aws sqs get-queue-attributes \
  --queue-url <dlq-url> \
  --attribute-names ApproximateNumberOfMessages \
  --region ap-south-1 \
  --profile ecommerce
```

### Investigation

Check the process-order Lambda logs:

```bash
aws logs tail /aws/lambda/ecommerce-dev-process-order \
  --region ap-south-1 \
  --since 30m \
  --profile ecommerce
```

### Resolution

Identify the original processing failure before replaying or deleting the DLQ message.

The DLQ prevents a permanently failing message from continuously blocking the main processing flow.

---

## 7. SNS Notification Is Not Triggering

### Symptoms

The process-order Lambda successfully publishes the order, but the notification Lambda does not process it.

### Expected Flow

```text
SQS
 |
 v
process-order Lambda
 |
 v
SNS
 |
 v
send-notification Lambda
```

### Check Notification Lambda Logs

```bash
aws logs tail /aws/lambda/ecommerce-dev-send-notification \
  --region ap-south-1 \
  --since 10m \
  --profile ecommerce
```

### Common Causes

- SNS subscription is missing
- SNS does not have permission to invoke Lambda
- Notification Lambda is failing
- Incorrect Lambda subscription configuration

---

## 8. SES Email Is Not Sent

### Symptoms

The notification Lambda runs, but the customer does not receive an email.

### Check Lambda Logs

```bash
aws logs tail /aws/lambda/ecommerce-dev-send-notification \
  --region ap-south-1 \
  --since 10m \
  --profile ecommerce
```

### SES Sandbox Consideration

The SES account is currently operating in the sandbox.

In sandbox mode, the sender and recipient addresses must be verified identities.

The project uses the verified sender:

```text
shivashankar199707@gmail.com
```

### Common Causes

- Recipient email is not verified
- Sender identity is not verified
- SES account is still in sandbox
- Lambda role lacks SES permissions
- Incorrect `SES_FROM_EMAIL`
- SES sending limit reached

---

## 9. CloudFront Cannot Be Created

### Symptoms

Terraform returns an AWS error similar to:

```text
AccessDenied:
Your account must be verified before you can add new CloudFront resources.
```

### Cause

The AWS account requires additional verification before CloudFront resources can be created.

### Current Project Status

CloudFront Terraform configuration is present in the repository, but the development deployment currently uses:

```text
Internet
   |
   v
ALB
   |
   v
ECS Fargate
```

### Resolution

Complete AWS account verification through AWS Support before attempting to create the CloudFront distribution again.

---

## 10. CloudWatch Alarm Shows INSUFFICIENT_DATA

### Symptoms

A newly created CloudWatch alarm displays:

```text
INSUFFICIENT_DATA
```

### Meaning

The alarm does not yet have enough metric datapoints to determine its state.

This can happen immediately after an alarm is created.

### Project Alarms

The project monitors:

```text
ECS CPU utilization
ALB target 5xx errors
SQS message backlog
```

### Resolution

Wait for CloudWatch metrics to be collected and evaluate the alarm again.

For example:

```bash
aws cloudwatch describe-alarms \
  --region ap-south-1 \
  --profile ecommerce
```

---

## 11. Terraform Reports No Configuration Files

### Symptoms

Running:

```bash
terraform plan
```

returns:

```text
No configuration files
```

### Cause

Terraform was executed from the repository root instead of the Terraform environment directory.

### Correct Location

```text
terraform/environments/dev
```

Move to the correct directory:

```bash
cd ~/aws-event-driven-ecommerce-platform/terraform/environments/dev
```

Then run:

```bash
terraform plan
```

---

## 12. Terraform Reports Unexpected Changes

### Check

Always run:

```bash
terraform plan
```

before applying changes.

Review:

```text
Plan: X to add, Y to change, Z to destroy.
```

### Important

Do not blindly run:

```bash
terraform apply
```

when Terraform shows unexpected resource replacements or deletions.

First identify which resource caused the change.

Useful commands include:

```bash
terraform state list
```

and:

```bash
terraform show
```

---

## 13. Lambda ZIP or Source Hash Changes Unexpectedly

### Symptoms

Terraform reports a Lambda code change even though the source appears unchanged.

### Check

Run:

```bash
terraform plan
```

If the plan shows only the Lambda source hash changing, inspect the Lambda source directory and generated files.

For example:

```bash
find ~/aws-event-driven-ecommerce-platform/lambda -maxdepth 3 -type f
```

### Prevention

Generated ZIP files should not be committed to Git.

The repository `.gitignore` includes:

```text
*.zip
```

Terraform generates the Lambda package during the deployment process.

---

## 14. Git Shows Generated Files

### Symptoms

Git shows files such as:

```text
*.zip
*.tfplan
.terraform/
*.tfstate
```

### Check

```bash
git status --short
```

### Expected

Generated Terraform and Lambda artifacts should not be committed.

The `.gitignore` contains:

```text
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
*.zip
```

### Resolution

If a generated file was already tracked:

```bash
git rm --cached <file>
```

Then commit the cleanup.

---

## 15. Docker Container Does Not Start

### Check Docker Image

```bash
docker images
```

Run the image locally:

```bash
docker run --rm -p 8000:8000 ecommerce-order-api:1.1
```

Test:

```bash
curl http://localhost:8000/health
```

Expected:

```json
{
  "status": "healthy",
  "service": "order-api"
}
```

### Common Causes

- Missing Python dependency
- Incorrect Dockerfile
- Incorrect Uvicorn command
- Application startup error
- Incorrect port mapping

---

## 16. Recommended Production Troubleshooting Sequence

For an order-processing failure, investigate from the outside toward the failed component:

```text
1. ALB
   |
2. ECS
   |
3. SQS
   |
4. Process Order Lambda
   |
5. SNS
   |
6. Send Notification Lambda
   |
7. SES
```

Check each component's:

- Status
- Logs
- IAM permissions
- Configuration
- Network connectivity
- CloudWatch metrics

This approach helps isolate the failure instead of changing multiple components at the same time.


