data "aws_region" "current" {}

locals {
    short_region = "${lower(substr(element(split("-", data.aws_region.current.name),0), 0, 1))}${lower(substr(element(split("-", data.aws_region.current.name),1), 0, 1))}${lower(substr(element(split("-", data.aws_region.current.name),2), 0, 1))}"
    common_tags = {
        "Region" = data.aws_region.current.name
        "Environment" = var.environment
        "Project" = var.project
    }
}

locals {
  naming = "${local.short_region}-${lower(var.environment)}-${lower(var.project)}"
}

data "aws_caller_identity" "current" {}

module "network" {
    source = "./modules/network"

    region      = data.aws_region.current.name
    naming      = local.naming
    common_tags = local.common_tags

    cidr_block = var.cidr_block
    az_count   = var.az_count
}

module "security" {
  source = "./modules/security"

  naming      = local.naming
  common_tags = local.common_tags

  vpc_id      = module.network.outputs.vpc_id
}

module "iam" {
  source = "./modules/iam"

  naming      = local.naming
  common_tags = local.common_tags

  s3_log_bucket  = var.s3_log_bucket
}

module "eks" {
  source = "./modules/eks"

  region      = data.aws_region.current.name
  naming      = local.naming
  common_tags = local.common_tags

  s3_log_bucket         = var.s3_log_bucket
  eks_api_public_access = var.eks_api_public_access
  k8s_version           = var.k8s_version
  security_data         = module.security.outputs
  network_data          = module.network.outputs
  iam_data              = module.iam.outputs
  cluster_log_types     = var.cluster_log_types
}

module "kubenetes" {
  source = "./modules/kubernetes"

  region        = data.aws_region.current.name
  prim_region   = var.prim_region
  fail_region   = var.fail_region
  naming        = local.naming
  s3_log_bucket = var.s3_log_bucket
  node_group    = module.eks.eks.node_group
}
