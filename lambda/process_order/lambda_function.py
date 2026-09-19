import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

AWS_REGION = os.getenv("AWS_REGION", "ap-south-1")
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")

sns = boto3.client("sns", region_name=AWS_REGION)


def lambda_handler(event, context):
    logger.info("Received event from SQS: %s", json.dumps(event))

    batch_item_failures = []

    for record in event.get("Records", []):
        message_id = record["messageId"]

        try:
            message_body = json.loads(record["body"])

            logger.info(
                "Processing order: %s",
                json.dumps(message_body)
            )

            if not SNS_TOPIC_ARN:
                raise RuntimeError("SNS_TOPIC_ARN environment variable is not configured")

            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject="E-Commerce Order Notification",
                Message=json.dumps(message_body)
            )

            logger.info(
                "Successfully published order %s to SNS topic %s",
                message_body.get("order_id"),
                SNS_TOPIC_ARN
            )

        except Exception as error:
            logger.error(
                "Failed to process message %s: %s",
                message_id,
                error
            )

            batch_item_failures.append({
                "itemIdentifier": message_id
            })

    return {
        "batchItemFailures": batch_item_failures
    }



