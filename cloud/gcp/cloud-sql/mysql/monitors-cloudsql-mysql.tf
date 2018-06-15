#
# FILTERS
#
data "template_file" "filter" {
  template = "$${filter}"

  vars {
    filter = "${var.filter_tags_use_defaults == "true" ?
             format("project_id:%s",var.project_id) :
             "${var.filter_tags_custom}"}"
  }
}

#
# MySQL Network Connections
#
resource "datadog_monitor" "network_connections" {
  name    = "[${var.environment}] Cloud SQL MySQL Network Connections (hard limit: ${var.network_connections_hard_limit}) {{#is_alert}}{{{comparator}}} {{threshold}}% ({{value}}%){{/is_alert}}{{#is_warning}}{{{comparator}}} {{warn_threshold}}% ({{value}}%){{/is_warning}}"
  message = "${coalesce(var.network_connections_message, var.message)}"

  type = "metric alert"

  query = <<EOF
  avg(${var.network_connections_timeframe}):
    avg:gcp.cloudsql.database.network.connections{${data.template_file.filter.rendered}}
    by {database_id}
    > ${var.network_connections_threshold_critical}
EOF

  thresholds {
    warning  = "${var.network_connections_threshold_warning}"
    critical = "${var.network_connections_threshold_critical}"
  }

  include_tags        = true
  notify_no_data      = true
  require_full_window = false
  renotify_interval   = 0
  notify_audit        = false
  timeout_h           = 0
  include_tags        = true
  locked              = false
  evaluation_delay    = "${var.delay}"
  new_host_delay      = "${var.delay}"
  silenced            = "${var.network_connections_silenced}"

  tags = [
    "team:gcp",
    "provider:gcp",
    "env:${var.environment}",
    "resource:cloud-sql",
    "engine:mysql",
  ]
}

#
# Replication Lag
#
resource "datadog_monitor" "replication_lag" {
  name    = "[${var.environment}] Cloud SQL MySQL Replication Lag too high"
  message = "${coalesce(var.replication_lag_message, var.message)}"

  type = "metric alert"

  query = <<EOF
    min(last_10m):
      avg:gcp.cloudsql.database.mysql.replication.seconds_behind_master{${data.template_file.filter.rendered}}
      by {database_id}
      > ${var.replication_lag_threshold_critical}
EOF

  thresholds {
    critical = "${var.replication_lag_threshold_critical}"
    warning  = "${var.replication_lag_threshold_warning}"
  }

  include_tags        = true
  notify_no_data      = true
  require_full_window = false
  renotify_interval   = 0
  notify_audit        = false
  timeout_h           = 0
  include_tags        = true
  locked              = false
  evaluation_delay    = "${var.delay}"
  new_host_delay      = "${var.delay}"
  silenced            = "${var.replication_lag_silenced}"

  tags = [
    "team:gcp",
    "provider:gcp",
    "env:${var.environment}",
    "resource:cloud-sql",
    "engine:mysql",
  ]
}
