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
