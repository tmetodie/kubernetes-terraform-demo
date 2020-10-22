variable "region" {
    type        = string
    description = "AWS region where solution should be deployed."
}

variable "short_region" {
    type = string
    description = "Short version of above defined AWS region. Eg. eu-west-1 >> ew1 ."
}

variable "environment" {
    type = string
    description = "Environment type. Eg. Development, UAT, Production."
}

variable "project" {
    type = string
    description = "Project name or abreviations."
}

# Network related
variable "cidr_block" {
    type = string
    description = "CIDR block for the created VPC."
}

variable "az_count" {
    type = number
    description = "Number of availability zones to utilize."
}

# EKS related
variable "eks_api_public_access" {
    type = bool
    description = "Should public access to the EKS API be allowed?"
}

variable "k8s_version" {
    type = string
    description = "Kubernetes version to be used."
}

variable "rds_creds" {
    type = map
    description = "(optional) describe your variable"
}

variable "s3_log_bucket" {
    type = string
    description = "(optional) describe your variable"
}

variable "elb_account_id" {
    type = string
    description = "(optional) describe your variable"
}