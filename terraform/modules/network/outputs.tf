output "outputs" {
  value       = {
    vpc_id        = aws_vpc.vpc.id
    pub_sbnt_ids  = aws_subnet.public.*.id
    priv_sbnt_ids = aws_subnet.private.*.id
    az            = ["${var.region}a", "${var.region}b", "${var.region}c"]
  }
  description = "VPC id, List of all public, private and db subnet IDs"
}