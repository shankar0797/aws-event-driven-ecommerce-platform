from fastapi import FastAPI, HTTPException
from datetime import datetime
import uuid
import json
import os
import boto3


app = FastAPI(
    title="Event-Driven E-Commerce API",
    description="Order API for AWS event-driven e-commerce platform",
    version="1.1.0"
)


AWS_REGION = os.getenv("AWS_REGION", "ap-south-1")
SQS_QUEUE_URL = os.getenv("SQS_QUEUE_URL")


sqs = boto3.client(
    "sqs",
    region_name=AWS_REGION
)


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "order-api"
    }


@app.post("/orders")
def create_order(order: dict):

    order_id = f"ORD-{uuid.uuid4().hex[:8].upper()}"

    order_event = {
        "order_id": order_id,
        "customer_name": order.get("customer_name"),
        "customer_email": order.get("customer_email"),
        "product": order.get("product"),
        "quantity": order.get("quantity"),
        "status": "PROCESSING",
        "created_at": datetime.utcnow().isoformat()
    }

    if not SQS_QUEUE_URL:
        raise HTTPException(
            status_code=500,
            detail="SQS_QUEUE_URL environment variable is not configured"
        )

    try:
        sqs.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps(order_event)
        )

    except Exception as error:
        print(f"Failed to send order to SQS: {error}")

        raise HTTPException(
            status_code=503,
            detail="Unable to queue order for processing"
        )

    return order_event



