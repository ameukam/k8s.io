/*
Copyright 2021 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

resource "google_monitoring_uptime_check_config" "http" {
  project          = var.project


  display_name = "test"
  timeout      = "10s"
  period       = "60s"

  http_check {
    port           = var.alert_http_check_port
    request_method = var.alert_http_check_method
    use_ssl        = true
    validate_ssl   = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project
      host       = "test"
    }
  }

}

resource "google_monitoring_alert_policy" "alert_policy" {
  display_name = "HTTP Uptime Check Alerting Policy"
  enabled      = var.enabled
  combiner     = "OR"

  conditions {
    display_name = "HTTP Uptime Check Alert"
    condition_threshold {
      filter     = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.label.check_id=\"${google_monitoring_uptime_check_config.http.uptime_check_id}\" AND resource.type=\"uptime_url\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      aggregations {
        # the alignment sets the window over which the metric is viewed
        alignment_period     = "1200s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.*"]
      }
      threshold_value = "2"
      trigger {
        count = "1"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.basic.id
  ]
}


resource "google_monitoring_notification_channel" "basic" {
  display_name = "Test Notification Channel"
  type         = "email"

  labels = {
    email_address = var.email_address
  }
}