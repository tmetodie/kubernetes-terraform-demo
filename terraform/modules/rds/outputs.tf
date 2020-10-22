output "rds_host" {
  value       = aws_db_instance.rds.address 
  description = "The RDS Hostname."
}