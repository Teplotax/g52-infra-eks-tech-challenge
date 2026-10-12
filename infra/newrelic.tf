# observabilidade do ambiente no new relic: dashboard, monitor de uptime e alertas.
# só cria se o ambiente tiver o secret NEW_RELIC_API_KEY (user key, NRAK-...)

locals {
  newrelic_enabled = var.newrelic_api_key != ""

  nr_app     = "tech-challenge-ms-${var.environment}"
  nr_lambda  = "g52-lambda-auth-${var.environment}"
  nr_monitor = "g52 health (${var.environment})"
}

# rest api compartilhado (g52-infra-gateway); o monitor pinga o /<ambiente>/health dele
data "aws_api_gateway_rest_api" "this" {
  count = local.newrelic_enabled ? 1 : 0
  name  = var.api_name
}

resource "newrelic_one_dashboard_json" "this" {
  count = local.newrelic_enabled ? 1 : 0

  json = templatefile("${path.module}/dashboard.json.tftpl", {
    account_id = var.newrelic_account_id
    env        = var.environment
    app        = local.nr_app
    cluster    = var.cluster_name
    lambda     = local.nr_lambda
  })
}

# ping não conta na cota de checks sintéticos do plano free
resource "newrelic_synthetics_monitor" "health" {
  count = local.newrelic_enabled ? 1 : 0

  name              = local.nr_monitor
  type              = "SIMPLE"
  period            = "EVERY_5_MINUTES"
  status            = "ENABLED"
  uri               = "https://${data.aws_api_gateway_rest_api.this[0].id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}/health"
  validation_string = "UP"
  verify_ssl        = true
  locations_public  = ["US_EAST_1"]
}

resource "newrelic_alert_policy" "this" {
  count = local.newrelic_enabled ? 1 : 0

  name                = "G52 Tech Challenge (${var.environment})"
  incident_preference = "PER_CONDITION"
}

# condições: chave = nome do alerta
locals {
  nr_conditions = {
    "Falha no processamento de OS" = {
      query     = "SELECT count(*) FROM Transaction WHERE appName = '${local.nr_app}' AND request.uri LIKE '/ordensDeServico%' AND http.statusCode >= 500"
      threshold = 0
      duration  = 300
      occur     = "at_least_once"
      delay     = 120
    }
    "Falha de integração (e-mail/PDF)" = {
      query     = "SELECT count(*) FROM IntegracaoFalha WHERE appName = '${local.nr_app}'"
      threshold = 0
      duration  = 300
      occur     = "at_least_once"
      delay     = 120
    }
    "Erros na Lambda de autenticação" = {
      query     = "SELECT sum(provider.errors.Sum) FROM ServerlessSample WHERE entityName LIKE '${local.nr_lambda}%'"
      threshold = 0
      duration  = 300
      occur     = "at_least_once"
      # integração aws chega por polling, com atraso
      delay     = 900
    }
    "Latência p95 alta (> 2s)" = {
      query     = "SELECT percentile(duration, 95) FROM Transaction WHERE appName = '${local.nr_app}' AND request.uri NOT LIKE '/actuator%'"
      threshold = 2
      duration  = 300
      occur     = "all"
      delay     = 120
    }
    "Taxa de erro alta (> 5%)" = {
      query     = "SELECT percentage(count(*), WHERE http.statusCode >= 500) FROM Transaction WHERE appName = '${local.nr_app}' AND request.uri NOT LIKE '/actuator%'"
      threshold = 5
      duration  = 300
      occur     = "all"
      delay     = 120
    }
    "App fora do ar (healthcheck)" = {
      query     = "SELECT count(*) FROM SyntheticCheck WHERE monitorName = '${local.nr_monitor}' AND result = 'FAILED'"
      threshold = 0
      duration  = 900
      occur     = "at_least_once"
      delay     = 120
    }
  }
}

resource "newrelic_nrql_alert_condition" "this" {
  for_each = local.newrelic_enabled ? local.nr_conditions : {}

  policy_id                    = newrelic_alert_policy.this[0].id
  type                         = "static"
  name                         = each.key
  enabled                      = true
  violation_time_limit_seconds = 86400

  nrql {
    query = each.value.query
  }

  critical {
    operator              = "above"
    threshold             = each.value.threshold
    threshold_duration    = each.value.duration
    threshold_occurrences = each.value.occur
  }

  aggregation_window = 60
  aggregation_method = "event_flow"
  aggregation_delay  = each.value.delay
}

# notificação por e-mail (opcional); sem e-mail os alertas só abrem issues no new relic
resource "newrelic_notification_destination" "email" {
  count = local.newrelic_enabled && var.newrelic_alert_email != "" ? 1 : 0

  name = "g52-email-${var.environment}"
  type = "EMAIL"

  property {
    key   = "email"
    value = var.newrelic_alert_email
  }
}

resource "newrelic_notification_channel" "email" {
  count = local.newrelic_enabled && var.newrelic_alert_email != "" ? 1 : 0

  name           = "g52-email-${var.environment}"
  type           = "EMAIL"
  destination_id = newrelic_notification_destination.email[0].id
  product        = "IINT"

  property {
    key   = "subject"
    value = "[g52 ${var.environment}] {{issueTitle}}"
  }
}

resource "newrelic_workflow" "this" {
  count = local.newrelic_enabled && var.newrelic_alert_email != "" ? 1 : 0

  name                  = "g52-${var.environment}"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "policy"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.this[0].id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.email[0].id
  }
}
