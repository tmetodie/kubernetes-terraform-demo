resource "aws_eks_cluster" "control_plane" {
  name     = "${var.naming}-eks"
  role_arn = var.iam_data.svc
  tags     = var.common_tags

  version = var.k8s_version

  # enabled_cluster_log_types = var.cluster_log_types

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

# resource "aws_lb" "frontend_elb" {
#   name               = "${var.naming}-frontend-elb"
#   internal           = false
#   load_balancer_type = "application"
#   # security_groups    = [aws_security_group.lb_sg.id]
#   subnets            = var.network_data.pub_sbnt_ids

#   enable_deletion_protection = true
#   enable_http2    = true
#   ip_address_type = "ipv4"

#   # access_logs {
#   #   bucket  = var.log_s3_name
#   #   prefix  = "${var.naming}-frontend-elb"
#   #   enabled = true
#   # }

#   tags = var.common_tags
# }

# resource "aws_lb_target_group" "frontend_elb_tg" {
#   name               = "${var.naming}-frontend-elb"

#   vpc_id      = var.network_data.vpc_id
#   port        = 80
#   protocol    = "HTTP"
#   target_type = "instance"

#   health_check {
#       enabled             = true
#       path                = "/"
#       port                = "443"
#       protocol            = "HTTP"
#       matcher             = "200-399"
#   }


#   tags = merge(
#     {
#       "Name" = "${var.naming}-eks-tg"
#     },
#     var.common_tags
#   )

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_lb_listener" "frontend_https" {
#   load_balancer_arn = aws_lb.frontend_elb.arn

#   port            = "443"
#   protocol        = "HTTPS"
#   certificate_arn = var.alb_cert_arn
#   ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.frontend_elb_tg.arn
#   }
# }

# resource "aws_lb_listener" "frontend_http" {
#   load_balancer_arn = aws_lb.frontend_elb.arn

#   port            = "80"
#   protocol        = "HTTP"

#   default_action {
#     type             = "redirect"
#     redirect {
#       port        = 443
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }


# resource "aws_lb_target_group_attachment" "test" {
#   target_group_arn = aws_lb_target_group.frontend_elb_tg.arn
#   target_id        = aws_lambda_function.test.arn
# }
