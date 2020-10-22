variable "naming" {
    type = string
    description = "Naming convention."
}

variable "vpc_id" {
    type = string
    description = "VPC Id to deploy resources."
}

variable "common_tags" {
    type = map
    description = "Common deployment tags."
}
