# Incident Report — Order Processing Failure and DLQ Recovery

## 1. Incident Summary

A controlled failure was introduced into the order-processing Lambda to validate the Dead Letter Queue (DLQ) behavior of the event-driven order processing architecture.

The test confirmed that repeatedly failing SQS messages are retried and eventually moved to the configured DLQ.

This was a controlled resilience test and not an unplanned production outage.

---

## 2. System

Application:

```text
Event-Driven E-Commerce Platform
```

AWS Region:

```text
ap-south-1
```

Affected workflow:

```text
ECS/Fargate
    |
    v
SQS Order Queue
    |
    v
Process Order Lambda
    |
    v
SNS
```

Failure isolation component:

```text
SQS Order DLQ
```

---

## 3. Incident Scenario

A test message was submitted with a controlled failure condition.

Test order ID:

```text
ORD-70575559
```

The order was intentionally configured to trigger a processing failure in the `process-order` Lambda.

The purpose was to verify:

- SQS retry behavior
- Lambda failure handling
- Maximum receive count
- DLQ redrive behavior
- CloudWatch logging
- Recovery procedure

---

## 4. Expected Behavior

The expected processing flow was:

```text
Order API
    |
    v
SQS Order Queue
    |
    v
Process Order Lambda
    |
    X
Processing Failure
    |
    v
SQS Retry
    |
    X
Processing Failure
    |
    v
SQS Retry
    |
    X
Processing Failure
    |
    v
DLQ
```

The configured maximum receive count was:

```text
3
```

After repeated processing failures, the message was expected to move to the DLQ.

---

## 5. Detection

The failure was detected by observing the SQS queue and Lambda processing behavior.

The test message eventually appeared in:

```text
ecommerce-dev-order-dlq
```

The message showed an approximate receive count of:

```text
4
```

This confirmed that the message had been repeatedly received before being moved to the DLQ.

---

## 6. Investigation

The first component investigated was the `process-order` Lambda.

CloudWatch logs were reviewed using:

```bash
aws logs tail /aws/lambda/ecommerce-dev-process-order \
  --region ap-south-1 \
  --since 30m \
  --profile ecommerce
```

The logs confirmed that the Lambda was receiving and attempting to process the test message.

The controlled failure condition prevented successful processing.

---

## 7. Root Cause

The root cause was the intentionally introduced test failure condition in the `process-order` Lambda.

The failure was deliberately introduced to validate the DLQ mechanism.

Therefore, this was a controlled resilience test rather than an accidental application failure.

---

## 8. Resolution

The temporary failure condition was removed from the Lambda source code.

The normal processing logic was restored:

```text
SQS
 |
 v
Process Order Lambda
 |
 v
SNS
 |
 v
Send Notification Lambda
 |
 v
SES
```

Terraform was then synchronized with the restored Lambda source.

The final Terraform validation returned:

```text
No changes.
```

This confirmed that the deployed infrastructure and the Terraform configuration were synchronized.

---

## 9. Validation After Recovery

After restoring the normal Lambda behavior, a normal order was submitted through the application.

The order successfully followed the complete workflow:

```text
ECS/Fargate
   |
   v
SQS
   |
   v
Process Order Lambda
   |
   v
SNS
   |
   v
Send Notification Lambda
   |
   v
SES
   |
   v
Customer Email
```

The SQS main queue returned to:

```text
ApproximateNumberOfMessages: 0
ApproximateNumberOfMessagesNotVisible: 0
```

The Lambda logs confirmed successful processing.

SES also successfully accepted the notification email.

---

## 10. Lessons Learned

### Lesson 1 — DLQ prevents endless retries

A DLQ provides a separate location for messages that repeatedly fail processing.

### Lesson 2 — CloudWatch logs are essential

Lambda logs provide the detailed information required to determine why a message failed.

### Lesson 3 — Controlled failure testing is valuable

Testing failure scenarios confirms that retry and recovery mechanisms work before an actual production failure occurs.

### Lesson 4 — Infrastructure and application changes should be synchronized

After restoring the Lambda source, Terraform was validated to ensure that the deployed infrastructure matched the configuration.

### Lesson 5 — Investigate before replaying messages

A DLQ message should be investigated before attempting to replay it. Otherwise, the same failure can occur again.

---

## 11. Production Troubleshooting Approach

For a real production incident, the investigation should follow the event path:

```text
ALB
 |
 v
ECS
 |
 v
SQS
 |
 v
Process Order Lambda
 |
 v
SNS
 |
 v
Send Notification Lambda
 |
 v
SES
```

For each component, verify:

- Resource status
- CloudWatch logs
- CloudWatch metrics
- IAM permissions
- Configuration
- Network connectivity
- Recent deployments or configuration changes

The objective is to identify the first component where the expected event flow stops.

---

## 12. Incident Status

```text
Status: Resolved
Type: Controlled resilience test
Impact: No production customer impact
DLQ behavior: Verified
Retry behavior: Verified
Normal order processing: Verified
Notification workflow: Verified
```

