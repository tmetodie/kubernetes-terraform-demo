locals {
    naming = "${lower(var.short_region)}-${lower(var.environment)}-${lower(var.project)}"
    common_tags = {
        "Region" = var.region
        "Environment" = var.environment
        "Project" = var.project
    }
}

data "aws_caller_identity" "current" {}

module "network" {
    source = "./modules/network"

    region      = var.region
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
  elb_account_id = var.elb_account_id
}

module "eks" {
  source = "./modules/eks"

  naming      = local.naming
  common_tags = local.common_tags

  eks_api_public_access = var.eks_api_public_access
  k8s_version           = var.k8s_version
  security_data         = module.security.outputs
  network_data          = module.network.outputs
  iam_data              = module.iam.outputs
}

module "rds" {
  source = "./modules/rds"

  naming      = local.naming
  common_tags = local.common_tags
  
  network_data  = module.network.outputs
  rds_creds     = var.rds_creds
  security_data = module.security.outputs
}

resource "null_resource" "deploy_service" {
  triggers = {
    build_number = timestamp()
  }

  provisioner "local-exec" {
    # command = "./deploy.sh ${module.eks.cluster_name} ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.naming}-cicd-ecr-web ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.naming}-cicd-ecr-api ${var.s3_log_bucket} ${element(module.security.outputs.ctrl_plane_sg_ids, 0)} ${element(module.security.outputs.ctrl_plane_sg_ids, 0)} ${module.rds.rds_host} ${module.security.outputs.alb_cert_arn} ${var.rds_creds.username} ${var.rds_creds.password}"
    command = "./deploy.sh ${module.eks.cluster_name} ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.naming}-cicd-ecr-web ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.naming}-cicd-ecr-api ${var.s3_log_bucket} ${element(module.security.outputs.ctrl_plane_sg_ids, 0)} ${element(module.security.outputs.ctrl_plane_sg_ids, 0)} ${module.rds.rds_host} 'arn:aws:acm:eu-central-1:490051574038:certificate/1ca5c5bb-016f-4988-ad1e-40abafe5cde1' ${var.rds_creds.username} ${var.rds_creds.password}"
    working_dir = "../../scripts"
    interpreter = ["/bin/bash", "-c"]
  }
}