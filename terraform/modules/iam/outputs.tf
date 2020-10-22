
output "outputs" {
  value       = {
    svc = aws_iam_role.eks_svc_role.arn
    node = aws_iam_role.eks_node.arn
  }
  description = "The ARNs of IAM roles of the cluster service and worker nodes."
}