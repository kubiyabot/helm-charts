#!/bin/bash

# Base URL and Authorization token
BASE_URL="https://<grafana-url>/api/dashboards/uid"
AUTH_TOKEN="<grafana-token>"

# List of dashboards in "file_name.json uuid" format
dashboards=(
    "under-dev-customer-runners-all-runners-state.json bea2idbz3hh4wf"
    "customer-runners-blackbox-exporter.json be7dg82wb5tkwa"
    "customer-runners-blackbox-exporter-alternate-view.json pS6ZuGV7z"
    "customer-runners-component-exporter-agent-manager.json fastapi-observability"
    "customer-runners-component-exporter-tool-manager.json tool-manager"
    "customer-runners-metrics-alloy-prometheus-components.json e324cc55567d7f3a8e32860ff8e6d0d9"
    "customer-runners-runner-health-overview.json k8s-app-health-dashboard"
    "customer-runners-runner-health-overview-by-components.json runner-health-detail4"
    "runner-namespace-kubernetes-state.json garysdevil-kube-state-metrics-v2"
)

# Loop through each dashboard and export it
for dashboard in "${dashboards[@]}"; do
    # Split the line into file name and UUID
    file_name=$(echo $dashboard | awk '{print $1}')
    uuid=$(echo $dashboard | awk '{print $2}')
    
    # Use curl to export the dashboard
    curl -X GET -H "Authorization: Bearer $AUTH_TOKEN" "$BASE_URL/$uuid" > "$file_name"
    
    echo "Exported $file_name"
done
