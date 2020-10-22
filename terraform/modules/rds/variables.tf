variable "naming" {
    type = string
    description = "Naming convention."
}

variable "rds_creds" {
    type = map
    description = "RDS username and password"
}

variable "network_data" {
    type = object({
        vpc_id        = string
        priv_sbnt_ids = list(string)
        pub_sbnt_ids  = list(string)
        db_sbnt_ids   = list(string)
        az            = list(string)
    })
    description = "(optional) describe your variable"
}

variable "security_data" {
    type = object({
        ctrl_plane_sg_ids = list(string)
        eks_kms_key_arn = string
    })
    description = "(optional) describe your variable"
}

variable "common_tags" {
    type = map
    description = "Common deployment tags."
}
