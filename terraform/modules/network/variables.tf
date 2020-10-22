variable "region" {
    type = string
    description = "AWS Region, used in deployment."
}

variable "naming" {
    type = string
    description = "Naming convention."
}

variable "cidr_block" {
    type = string
    description = "VPC CIDR Block."
}

variable "az_zones" {
    type        = list
    description = "List of all availability zones, used in deployment."
    default     = ["a", "b", "c", "d", "e", "f"]
}

variable "az_count" {
    type = number
    description = "Number of availability zones, used in deployment."
}

variable "common_tags" {
    type = map
    description = "Common deployment tags."
}
