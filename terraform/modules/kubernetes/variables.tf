variable "region" {
    type        = string
    description = "AWS region where solution should be deployed."
}

variable "prim_region" {
    type        = string
    description = "Primary AWS region where solution should be deployed."
}

variable "fail_region" {
    type        = string
    description = "Failover AWS region where solution should be deployed."
}

variable "naming" {
    type = string
    description = "Naming convention."
}

variable "s3_log_bucket" {
    type = string
    description = "(optional) describe your variable"
}

variable "node_group" {
  type = string
  description = "Name of the Node Pool for EKS cluster."
}
