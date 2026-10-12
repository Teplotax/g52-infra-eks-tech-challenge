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

variable "rds_clients_security_group_name" {
  type = string
}

variable "tag_subnets_for_elb" {
  type    = bool
  default = true
}

# vazio = sem new relic no cluster (vem do secret NEW_RELIC_LICENSE_KEY do ambiente)
variable "newrelic_license_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "newrelic_account_id" {
  type    = number
  default = 8613587
}

# user key (NRAK-...) pra criar dashboard/alertas/monitor; vem do secret NEW_RELIC_API_KEY do ambiente
variable "newrelic_api_key" {
  type      = string
  default   = ""
  sensitive = true
}

# e-mail que recebe os alertas; vazio = só issues no new relic
variable "newrelic_alert_email" {
  type    = string
  default = ""
}

# rest api compartilhado (g52-infra-gateway), pro monitor de uptime
variable "api_name" {
  type    = string
  default = "api-g52-tech-challenge-v1"
}
