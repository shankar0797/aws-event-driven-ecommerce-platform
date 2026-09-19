import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

AWS_REGION = os.getenv("AWS_REGION", "ap-south-1")
SES_FROM_EMAIL = os.getenv("SES_FROM_EMAIL")

ses = boto3.client("sesv2", region_name=AWS_REGION)


def lambda_handler(event, context):
    logger.info("Received SNS event: %s", json.dumps(event))

    for record in event.get("Records", []):
        sns_message = record["Sns"]["Message"]

        try:
            order = json.loads(sns_message)

            order_id = order.get("order_id")
            customer_email = order.get("customer_email")

            if not SES_FROM_EMAIL:
                raise RuntimeError(
                    "SES_FROM_EMAIL environment variable is not configured"
                )

            if not customer_email:
                raise ValueError(
                    f"Customer email is missing for order {order_id}"
                )

            subject = f"Order Confirmation - {order_id}"

            body = f"""
Hello {order.get("customer_name", "Customer")},

Your order has been received successfully.

Order ID: {order_id}
Product: {order.get("product")}
Quantity: {order.get("quantity")}
Status: {order.get("status")}

Thank you for shopping with us.

E-Commerce Team
""".strip()

            response = ses.send_email(
                FromEmailAddress=SES_FROM_EMAIL,
                Destination={
                    "ToAddresses": [customer_email]
                },
                Content={
                    "Simple": {
                        "Subject": {
                            "Data": subject
                        },
                        "Body": {
                            "Text": {
                                "Data": body
                            }
                        }
                    }
                }
            )

            logger.info(
                "Email sent successfully for order %s. MessageId: %s",
                order_id,
                response.get("MessageId")
            )

        except Exception as error:
            logger.error(
                "Failed to send notification: %s",
                error
            )
            raise

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Notification processed successfully"
        })
    }

