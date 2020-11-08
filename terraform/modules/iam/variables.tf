variable "naming" {
    type = string
    description = "Naming convention."
}

variable "s3_log_bucket" {
    type = string
    description = "(optional) describe your variable"
}

variable "common_tags" {
    type = map
    description = "Common deployment tags."
}
