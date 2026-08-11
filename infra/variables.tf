variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type = string
}

variable "app_namespace" {
  type    = string
  default = "tech-challenge"
}

variable "subnet_ids" {
  type = list(string)
}

variable "console_user_arn" {
  type = list(string)
}

variable "destroy" {
  type    = bool
  default = false
}