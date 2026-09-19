import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info("Received event from SQS: %s", json.dumps(event))

    for record in event.get("Records", []):
        message_body = record["body"]

        logger.info(
            "Processing SQS message: %s",
            message_body
        )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Order messages processed successfully"
        })
    }
