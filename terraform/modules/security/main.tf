resource "aws_security_group" "control_plane" {
  name        = "${var.naming}-control-plane-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.naming}-control-plane-sg"
  }
}

resource "aws_kms_key" "eks" {
  description              = "KMS key for EKS encryption."
  is_enabled               = true
  enable_key_rotation      = true
  customer_master_key_spec = "SYMMETRIC_DEFAULT"

  tags = merge({Name="${var.naming}-kms"}, var.common_tags)
}
