from fastapi import FastAPI
from datetime import datetime
import uuid

app = FastAPI(
    title="Event-Driven E-Commerce API",
    description="Order API for AWS event-driven e-commerce platform",
    version="1.0.0"
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

    return {
        "order_id": order_id,
        "customer_name": order.get("customer_name"),
        "customer_email": order.get("customer_email"),
        "product": order.get("product"),
        "quantity": order.get("quantity"),
        "status": "PROCESSING",
        "created_at": datetime.utcnow().isoformat()
    }
