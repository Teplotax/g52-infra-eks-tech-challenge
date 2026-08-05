variable "ecs_name" {
  description = "Name of the cluster"
}

variable "container_insights" {
  description = "Bool for enabling container_insights"
  default     = false
}

variable "aws_region" {
  type    = string
  default = "sa-east-1"
}

variable "environment" {
  type = string
}

variable "destroy" {
  type    = bool
  default = false
}