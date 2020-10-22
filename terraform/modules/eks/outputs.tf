output "cluster_name" {
  value = aws_eks_cluster.control_plane.id
  description = "Name of the EKS cluster."
}