#!/bin/bash

# Base URL and Authorization token
BASE_URL="https://<grafana-url>/api/dashboards/uid"
AUTH_TOKEN="<grafana-token>"
# List of dashboards in "file_name.json uuid" format
dashboards=(
    "dashboard-name.json <dashboard-uuid>"
    # ...
    # ...
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
