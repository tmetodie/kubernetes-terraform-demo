resource "aws_eks_cluster" "control_plane" {
  name     = "${var.naming}-eks"
  role_arn = var.iam_data.svc
  tags     = var.common_tags

  version = var.k8s_version

  enabled_cluster_log_types = var.cluster_log_types

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = var.eks_api_public_access
    security_group_ids      = var.security_data.ctrl_plane_sg_ids
    subnet_ids              = concat(var.network_data.pub_sbnt_ids, var.network_data.priv_sbnt_ids)
  }

  encryption_config {
    resources = ["secrets"]

    provider {
      key_arn = var.security_data.eks_kms_key_arn
    }
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name '${var.naming}-eks' --region '${var.region}'"
  }
}

resource "aws_eks_node_group" "node_pool" {
  cluster_name    = aws_eks_cluster.control_plane.name
  node_group_name = "${var.naming}-node-pool"
  node_role_arn   = var.iam_data.node
  subnet_ids      = var.network_data.priv_sbnt_ids

  ami_type       = "AL2_x86_64"
  disk_size      = 50
  instance_types = ["t3.medium"]
  labels         = var.common_tags

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  tags = var.common_tags
}
