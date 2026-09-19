aws_region        = "ap-south-1"
aws_profile       = "ecommerce"
project_name      = "ecommerce"
environment       = "dev"
ecs_cpu           = 256
ecs_memory        = 512
ecs_desired_count = 2
container_name    = "order-api"
container_port    = 8000
image_tag         = "1.0"

