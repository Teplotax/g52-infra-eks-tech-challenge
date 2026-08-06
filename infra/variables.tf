variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.31"
}

variable "aws_region" {
  type    = string
  default = "sa-east-1"
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "app_namespace" {
  type    = string
  default = "tech-challenge"
}

variable "destroy" {
  type    = bool
  default = false
}
