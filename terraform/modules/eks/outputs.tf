output "eks" {
  value = {
    cluster_name = aws_eks_cluster.control_plane.id
    node_group = aws_eks_node_group.node_pool.id
  }
  description = "EKS cluster data."
}
