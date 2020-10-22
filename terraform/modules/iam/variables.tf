variable "naming" {
    type = string
    description = "Naming convention."
}

variable "s3_log_bucket" {
    type = string
    description = "(optional) describe your variable"
}

variable "elb_account_id" {
    type = string
    description = "https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html"
}

variable "common_tags" {
    type = map
    description = "Common deployment tags."
}
