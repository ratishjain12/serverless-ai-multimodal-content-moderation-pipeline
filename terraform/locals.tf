locals {
  project = "content-moderation"
  env     = var.environment

  name_prefix = "${local.project}-${local.env}"

  tags = {
    Project     = local.project
    Environment = local.env
    ManagedBy   = "Terraform"
  }
}
