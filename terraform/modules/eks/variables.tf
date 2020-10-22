variable "naming" {
    type = string
    description = "Naming convention"
}

variable "eks_api_public_access" {
    type = bool
    description = "Public Access to EKS Kubernetes API enabled?"
}

variable "k8s_version" {
    type = string
    description = "The Kubernetes cluster version"
}

variable "network_data" {
    type = object({
        vpc_id = string
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

variable "iam_data" {
    type = map
    description = "(optional) describe your variable"
}

variable "common_tags" {
    type = map
    description = "Common deployment tags"
}
