resource "grafana_rule_group" "rule_group_0000" {
  org_id           = 1
  name             = "Runners Cumulative Health"
  folder_uid       = "aedcbv9pygdtsf"
  interval_seconds = 300

  rule {
    name      = "Customer Runners Health"
    condition = "C"

    data {
      ref_id = "RunnerHealthScore"

      relative_time_range {
        from = 900
        to   = 0
      }

      datasource_uid = "defaultazuremonitorworkspace-eus"
      model          = "{\"datasource\":{\"type\":\"prometheus\",\"uid\":\"defaultazuremonitorworkspace-eus\"},\"editorMode\":\"code\",\"exemplar\":false,\"expr\":\"(\\n  ((sum by (organization, runner) ( rate(response_status{status=~\\\"2..\\\", namespace=~\\\"$namespace|.*\\\", organization!=\\\"\\\", app=\\\"tool-manager\\\", kubiya_type=\\\"customers-runners\\\"}[5m])) / sum by (organization, runner) (rate(http_requests_total{namespace=~\\\"$namespace|.*\\\", organization!=\\\"\\\", app=\\\"tool-manager\\\", kubiya_type=\\\"customers-runners\\\"}[5m])) ) * 100)\\n+ \\n((sum by (organization, runner) ( rate(agent_manager_http_requests_total{status=~\\\"2..\\\", namespace=~\\\"$namespace|.*\\\", organization!=\\\"\\\", app=\\\"agent-manager\\\", kubiya_type=\\\"customers-runners\\\"}[5m]) ) / sum by (organization, runner) ( rate(agent_manager_http_requests_total{namespace=~\\\"$namespace|.*\\\", organization!=\\\"\\\", app=\\\"agent-manager\\\", kubiya_type=\\\"customers-runners\\\"}[5m]) )) * 100)\\n+\\n(( sum by (organization, runner) ( avg_over_time( kube_pod_status_ready{ namespace=~\\\"$namespace|.*\\\", organization!=\\\"\\\", kubiya_type=\\\"customers-runners\\\", condition=\\\"true\\\" }[5m] ) * on (pod) group_left(label_app_kubernetes_io_kubiya_runner_component) kube_pod_labels{ namespace=~\\\"$namespace|.*\\\", organization!=\\\"\\\", kubiya_type=\\\"customers-runners\\\", label_job_name=\\\"\\\" } and on (pod) kube_pod_labels{label_app_kubernetes_io_kubiya_runner_component!=\\\"\\\"} ) / count by (organization, runner) ( kube_pod_labels{ namespace=~\\\"$namespace|.*\\\", organization!=\\\"\\\", kubiya_type=\\\"customers-runners\\\", label_app_kubernetes_io_kubiya_runner_component!=\\\"\\\", label_job_name=\\\"\\\" })) * 100)\\n+\\n(( 1 - clamp_max( sum by (organization, runner)( rate(kube_pod_container_status_restarts_total{ namespace=~\\\"$namespace|.*\\\", organization!=\\\"\\\", kubiya_type=\\\"customers-runners\\\", label_job_name=\\\"\\\" }[5m]) * on (pod) group_left(label_app_kubernetes_io_kubiya_runner_component) kube_pod_labels{ namespace=~\\\"$namespace|.*\\\", organization!=\\\"\\\", kubiya_type=\\\"customers-runners\\\", label_job_name=\\\"\\\", label_app_kubernetes_io_kubiya_runner_component!=\\\"\\\" } ) * 300 / 1.0 , 1)) * 100)\\n+\\n(avg by (organization, runner) ( avg_over_time(probe_success{ namespace=~\\\"$namespace|.*\\\", organization!=\\\"\\\", kubiya_type=\\\"customers-runners\\\", exporter=\\\"blackbox-exporter\\\"}[5m]) ) * 100)\\n) /5\",\"format\":\"time_series\",\"instant\":false,\"interval\":\"1m\",\"intervalMs\":300000,\"legendFormat\":\"{{organization}}/{{runner}}\",\"maxDataPoints\":43200,\"range\":true,\"refId\":\"RunnerHealthScore\"}"
    }
    data {
      ref_id = "ReducedRunnersScores"

      relative_time_range {
        from = 900
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"RunnerHealthScore\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"last\",\"refId\":\"ReducedRunnersScores\",\"settings\":{\"mode\":\"\"},\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 900
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[100],\"type\":\"lt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"ReducedRunnersScores\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "Alerting"
    exec_err_state = "Alerting"
    for            = "5m"
    annotations = {
      __dashboardUid__ = "fegau55dgmgaod"
      __panelId__      = "17"
      description      = "Cumulative Runner Health Score is below the threshold for >5mins."
      summary          = "One or more runner components are not healthy."
    }
    labels = {
      component = "runner"
    }
    is_paused = false
  }
}
