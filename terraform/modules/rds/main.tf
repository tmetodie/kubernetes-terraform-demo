resource "aws_db_subnet_group" "rds" {
  name        = "${var.naming}-rds-sg-group"
  subnet_ids  = var.network_data.db_sbnt_ids
}

resource "aws_db_instance" "rds" {
  identifier                      = "${var.naming}-rds"
  allocated_storage               = 50
  max_allocated_storage           = 300
  engine                          = "postgres"
  engine_version                  = "12.3"
  instance_class                  = "db.m3.medium"
  storage_type                    = "gp2"
  username                        = var.rds_creds.username
  password                        = var.rds_creds.password
  name                            = var.rds_creds.db_name
  vpc_security_group_ids          = var.security_data.ctrl_plane_sg_ids
  db_subnet_group_name            = aws_db_subnet_group.rds.id
  multi_az                        = true
  backup_window                   = "23:00-01:00"
  maintenance_window              = "Sun:01:30-Sun:03:30"
  backup_retention_period         = 7
  copy_tags_to_snapshot           = true
  deletion_protection             = true
  storage_encrypted               = true
  kms_key_id                      = var.security_data.eks_kms_key_arn
  skip_final_snapshot             = false
  final_snapshot_identifier       = "${var.naming}-final-${md5(timestamp())}"
#   replicate_source_db             = true
  auto_minor_version_upgrade      = true

  tags = merge(
      {"Name" = "${var.naming}-rds"},
      var.common_tags
  )

  lifecycle {
    ignore_changes = [
        tags,
    ]
  }
}