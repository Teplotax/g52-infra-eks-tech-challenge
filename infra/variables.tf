variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
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

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_cidrs" {
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
