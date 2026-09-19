locals {
  name_prefix = "${var.project_name}-${var.environment}"
}


# ---------------------------------------------------------
# ECR
# ---------------------------------------------------------

module "ecr" {
  source = "../../modules/ecr"

  repository_name = "${local.name_prefix}-order-api"
}


# ---------------------------------------------------------
# VPC
# ---------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  vpc_name             = "${local.name_prefix}-vpc"
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  project_name         = var.project_name
  environment          = var.environment
}


# ---------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------

module "alb" {
  source = "../../modules/alb"

  alb_name          = "${local.name_prefix}-alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  project_name      = var.project_name
  environment       = var.environment

}
module "ecs" {
  source = "../../modules/ecs"

  cluster_name = "${local.name_prefix}-cluster"
  service_name = "${local.name_prefix}-order-api"

  container_name  = var.container_name
  container_image = "${module.ecr.repository_url}:${var.image_tag}"
  container_port  = var.container_port

  cpu           = var.ecs_cpu
  memory        = var.ecs_memory
  desired_count = var.ecs_desired_count

  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.alb.ecs_security_group_id
  target_group_arn      = module.alb.target_group_arn

  log_group_name = "/ecs/${local.name_prefix}-order-api"
  sqs_queue_arn  = module.sqs.queue_arn
  sqs_queue_url  = module.sqs.queue_url

  project_name = var.project_name
  environment  = var.environment
}

# ---------------------------------------------------------
# SQS Module
# ---------------------------------------------------------

module "sqs" {
  source = "../../modules/sqs"

  queue_name = "${local.name_prefix}-order-queue"
  dlq_name   = "${local.name_prefix}-order-dlq"

  max_receive_count          = 3
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600

  project_name = var.project_name
  environment  = var.environment
}

module "lambda" {
  source = "../../modules/lambda"

  function_name = "${local.name_prefix}-process-order"
  source_dir    = "../../../lambda/process_order"

  runtime     = "python3.11"
  handler     = "lambda_function.lambda_handler"
  timeout     = 30
  memory_size = 256

  sqs_queue_arn = module.sqs.queue_arn
  sns_topic_arn = module.sns.topic_arn

  project_name = var.project_name
  environment  = var.environment
}

module "sns" {
  source = "../../modules/sns"

  topic_name   = "${local.name_prefix}-order-notifications"
  project_name = var.project_name
  environment  = var.environment
}


module "notification_lambda" {
  source = "../../modules/notification_lambda"

  function_name = "${local.name_prefix}-send-notification"
  source_dir    = "../../../lambda/send_notification"

  runtime     = "python3.11"
  handler     = "lambda_function.lambda_handler"
  timeout     = 30
  memory_size = 256

  sns_topic_arn = module.sns.topic_arn

  ses_from_email = "shivashankar199707@gmail.com"

  project_name = var.project_name
  environment  = var.environment
}
