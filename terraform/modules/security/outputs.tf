output "outputs" {
  value       = {
    ctrl_plane_sg_ids = aws_security_group.control_plane.*.id
    eks_kms_key_arn   = aws_kms_key.eks.arn
    alb_cert_arn      = aws_acm_certificate.acm_cert.arn
  }
  description = "The ID of the EKS security group, used for control plane traffic; ARN of KMS, used for EKS object encryption; ARN of ACM Certificate, used for ALB."
}
