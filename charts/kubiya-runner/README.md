# Kubiya Runner

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/kubiya-helm-charts)](https://artifacthub.io/packages/search?repo=kubiya-helm-charts)

A Helm chart for deploying the Kubiya Runner.

## Table of Contents

- [Kubiya Runner](#kubiya-runner)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Directory Structure](#directory-structure)
  - [Prerequisites](#prerequisites)
  - [Permissions](#permissions)
  - [Components](#components)
    - [Agent Manager](#agent-manager)
    - [Kubiya Operator](#kubiya-operator)
    - [Tool Manager](#tool-manager)
    - [Workflow Engine](#workflow-engine)
    - [Image Updater](#image-updater)
  - [Dependencies \& Compatibility Matrix](#dependencies--compatibility-matrix)
    - [Helm Dependencies](#helm-dependencies)
    - [Container Images](#container-images)
  - [Monitoring \& Telemetry](#monitoring--telemetry)
    - [Security](#security)
    - [Architecture](#architecture)
    - [Grafana Alloy Configuration](#grafana-alloy-configuration)
  - [Azure Prometheus Integration](#azure-prometheus-integration)
  - [Grafana Dashboards](#grafana-dashboards)
    - [Single View Runners Cumulative Health Score](#single-view-runners-cumulative-health-score)
    - [Health Overview by Components](#health-overview-by-components)
    - [Runner Health Overview](#runner-health-overview)
    - [Tool Manager Dashboard](#tool-manager-dashboard)
    - [Agent Manager Dashboard](#agent-manager-dashboard)
    - [Kubernetes State Dashboard](#kubernetes-state-dashboard)
    - [Alloy Dashboard](#alloy-dashboard)
    - [Blackbox Exporter Dashboards](#blackbox-exporter-dashboards)
  - [Dashboards as a Code](#dashboards-as-a-code)
  - [K8s Resources Definitions](#k8s-resources-definitions)
  - [Security](#security-1)
  - [Optional Permissions Extensions:](#optional-permissions-extensions)
- [Deployment](#deployment)
  - [Minimum Required Configuration \& Values Passing](#minimum-required-configuration--values-passing)
  - [Installation](#installation)
  - [Update](#update)
  - [Using Name Overrides](#using-name-overrides)
  - [Environment Variables Management](#environment-variables-management)

## Overview

This repository contains the Helm chart for deploying the Kubiya Runner, a key component of the Kubiya platform for orchestrating and managing automation workflows. 

## Directory Structure

```shell
kubiya-runner/
├── Chart.yaml                                      # Chart metadata
├── values.yaml                                     # Default values for the chart
├── templates/                                      # Templates files
│   ├── components/                                 # Runner Components
│   │   ├── agent-manager/                         # Manages Kubiya agents lifecycle
│   │   ├── kubiya-operator/                       # Controls operational aspects
│   │   ├── tool-manager/                          # Handles tool execution
│   │   └── image-updater/                         # Automatic image updates
│   ├── alloy-configMap.yaml                       # Alloy configuration
│   └── shared-secrets.yaml                        # Secrets shared between runner components
│   └── _helpers.tpl                               # Helpers funtions for Helm Chart templates rendering
└── charts/                                        # Dependencies (subcharts)
    ├── dagger-helm/                               # Container runtime for workflows
    ├── kube-state-metrics/                        # Cluster-level metrics
    └── alloy/                                     # Grafana Alloy telemetry collector
```

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure
- NATS credentials for messaging
- Registry TLS certificates (if using private registry)

## Permissions

## Components

### Agent Manager

Repository: [kubiya-agent-manager](https://github.com/kubiyabot/kubiya-agent-manager)

The Agent Manager handles lifecycle management of Kubiya agents within the cluster.

### Kubiya Operator

Repository: [kubiya-operator](https://github.com/kubiyabot/kubiya-operator)

The Kubiya Operator manages operational aspects and configuration of the runner components.

### Tool Manager

The Kubiya Tool Manager is a high-performance, container-native utility designed for declarative management and execution of agent tools across diverse computing environments. It provides a scalable, stateless architecture for tool orchestration, supporting both local development and enterprise-scale Kubernetes deployments.

Full documentation is available [in project repository](https://github.com/kubiyabot/tool-manager).

- Executes tools within the cluster
- Integrates with Dagger for container runtime
- Includes SDK server for tool execution

### Workflow Engine

The Workflow Engine is responsible for managing and executing workflows in the Kubiya Runner. It provides a scalable, containerized environment for workflow execution and orchestration.

- Manages workflow execution and orchestration
- Communicates with the Tool Manager for tool execution
- Provides workflow status and metrics

### Image Updater

**TBD, (depricated approach)**

```
- Checks for updates of latest stable image versions via CronJob (hourly by default).
- Automatic updates for runner components (agent-manager, tool-manager, sdk-server) from stable release JSON file hosted in [S3 bucket](https://kubiya-cli.s3.amazonaws.com/stable/kubiya_versions.json).
```
## Dependencies & Compatibility Matrix

This chart (as of version 0.8.0) is tested to be compatible with the following versions of container images and Helm dependencies.

### Helm Dependencies

| Chart              | Version | App Version |
|--------------------|---------|-------------|
| dagger-helm        | 0.4.1   | 0.11.6      |
| kube-state-metrics | 5.27.0  | 2.14.0      |
| alloy              | 0.10.1  | v1.5.1      |

### Container Images

| Component          | Image                                                 | Version/Tag |
|--------------------|-------------------------------------------------------|-------------|
| Agent Manager      | ghcr.io/kubiyabot/agent-manager                       | v0.4.3      |
| Kubiya Operator    | ghcr.io/kubiyabot/kubiya-operator                     | runner_v2   |
| Tool Manager       | ghcr.io/kubiyabot/tool-manager                        | 0.5.4       |
| SDK Server         | ghcr.io/kubiyabot/sdk-py                              | v1.20.0     |
| Workflow Engine    | ghcr.io/kubiyabot/workflow-engine                     | v1.46.1     |
| Image Updater      | ghcr.io/kubiyabot/kubernetes                          | 1.32.0      |
| Dagger Engine      | ghcr.io/kubiyabot/kubiya-registry                     | v0.2.1      |
| Kube State Metrics | registry.k8s.io/kube-state-metrics/kube-state-metrics | v2.14.0     |
| Grafana Alloy      | grafana/alloy                                         | v1.5.1      |

## Monitoring & Telemetry

The `kubiya-runner` uses [Grafana Alloy](https://grafana.com/docs/alloy/latest/) for metrics collection from multiple customer runner deployments.
Alloy scrapes data from a set of targets (pods, services, etc.) which expose metrics on an endpoint (usually `/metrics`), processes them (filters, adds runner deployment labels, etc.) and pushes via Prometheus native `remote_writes` into **Azure Managed Prometheus**.

Later `kubiya-runner` chart releases expect to use Alloy for other types of telemetry data collection (such as logs and traces). **Alloy** also fully compatible with OpenTelemetry and can be configured to listen/send messages in `OTEL` format if needed, has a long list of vendor platforms and message formats compatibility and a rich set of data processing modules. 

###  Security

Both `Alloy` and `kube-state-metrics` has limited RBAC permissions and configured to collect only data from same kubernetes namespace where `kubiya-runner` is deployed (`kubiya` by default).
`Alloy` runs as non-root user.

### Architecture

```mermaid
graph LR
H[alloy-self-metrics]
A[kube-state-metrics]
B[blackbox-exporter]
C[tool-manager exporter]
D[agent-manager exporter]
E[grafana alloy]
F[azure managed prometheus]
G[grafana dashboards]
W[workflow-engine exporter (under dev)]
subgraph kubiya-runner
    A ---> E
    B ---> E
    C ---> E
    D ---> E
    H ---> E
    W ---> E
    E
end
E ---> F
F ---> G
```

### Grafana Alloy Configuration
  
1. **Resource Management**

  Default resource limits for `alloy`
    ```yaml
    resources:
      limits:
        cpu: 1
        memory: 1Gi
      requests:
        cpu: 100m
        memory: 128Mi
    ```
  `alloy` resource estimation guidelines available at: https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/
  
2. **Resources & Data Collection Configuration**

**To minimizes resource usage and cost on both the client and server sides, telemetry collection strategy focuses on deploying and configuring components to capture only the metrics essential for current business and operational goals. This pattern is highly recommended keeping when contributing.**

Alloy is configured with a single scrape interval, collecting metrics from all targets once every 60 seconds. As a result, 60 seconds is the maximum precision for all metric visualizations and alerting.

If this level of precision is insufficient, the scrape interval can be adjusted—either increased or decreased—to balance resource impact. These adjustments can be applied globally or to specific targets via `values.yaml`:

```yaml
  alloy:
    scrapeIntervals:
      default: 60s
      runnerExporters: 60s
      alloyExporter: 60s
      blackboxExporter: 60s
      kubeStateMetrics: 60s
      cadvisor: 60s (disabled by default)
```
## Azure Prometheus Integration

Required set of environment variables to be set for Azure Managed Prometheus remote writes support:

- `AZURE_REMOTE_WRITE_URL`: Azure Prometheus endpoint
- `AZURE_CLIENT_ID`: Azure service principal client ID
- `AZURE_CLIENT_SECRET`: Azure service principal secret
- `AZURE_TOKEN_URL`: Azure OAuth token URL

These variables confurable via `values.yaml` `alloy.alloy.extraEnv`)

## Grafana Dashboards

Grafana dashboards JSONs available in the `kubiya-runner` and located in `helm-charts/charts/kubiya-runner/_grafana/dashboards/`, alerts as code can be found under `helm-charts/charts/kubiya-runner/_grafana/alerts`

### Single View Runners Cumulative Health Score

![Single View Runners Cumulative Health Score](_docs/all-runners-cumulative-health.png)

Dashboard monitors health using a composite scoring system. Each runner's cumulative health score is calculated as the unweighted average of five key health signals, each normalized to a 0-100% scale:

```
(
  + Tool-Manager HTTP Success Rate (%)
  + Agent-Manager HTTP Success Rate (%) 
  + Pod Ready Status (%)
  + Pod Restart Stability (%)
  + Probe Success Rate (%)
) / 5
```

**Individual Health Signal Formulas and PromQL Functions**

1. **Tool-Manager HTTP Success Rate**
   ```
   (sum by (organization, runner) (rate(response_status{status=~"2..", app="tool-manager"}[5m])) / 
    sum by (organization, runner) (rate(http_requests_total{app="tool-manager"}[5m]))) * 100
   ```
   - `rate()`: Calculates the per-second rate of successful responses over 5-minute window
   - `sum by`: Aggregates metrics by organization and runner
   - Purpose: Measures percentage of successful (2xx) HTTP responses from the Tool Manager

2. **Agent-Manager HTTP Success Rate**
   ```
   (sum by (organization, runner) (rate(agent_manager_http_requests_total{status=~"2.."}[5m])) /
    sum by (organization, runner) (rate(agent_manager_http_requests_total[5m]))) * 100
   ```
   - Similar functions as Tool-Manager rate, applied to Agent Manager metrics
   - Purpose: Measures percentage of successful HTTP responses from the Agent Manager

3. **Pod Ready Status**
   ```
   (sum by (organization, runner) (avg_over_time(kube_pod_status_ready{condition="true"}[5m]) 
    * on (pod) group_left(label_app_kubernetes_io_kubiya_runner_component) 
    kube_pod_labels{label_app_kubernetes_io_kubiya_runner_component!=""}) /
    count by (organization, runner) (kube_pod_labels{label_app_kubernetes_io_kubiya_runner_component!=""})) * 100
   ```
   - `avg_over_time()`: Smooths pod ready status over 5 minutes
   - `* on (pod) group_left()`: Joins metrics on pod label to include component information
   - Purpose: Calculates percentage of runner pods in "ready" state

4. **Pod Restart Stability**
   ```
   (1 - clamp_max(sum by (organization, runner)(rate(kube_pod_container_status_restarts_total[5m]) 
    * on (pod) group_left(label_app_kubernetes_io_kubiya_runner_component) 
    kube_pod_labels{label_app_kubernetes_io_kubiya_runner_component!=""}) * 300 / 1.0, 1)) * 100
   ```
   - `clamp_max()`: Caps the maximum value at 1
   - `* 300 / 1.0`: Normalizes to consider 1 restart per 5 minutes (300s) as problematic
   - Purpose: Penalizes container restarts (0 restarts = 100%, 1+ restart per 5 minutes = 0%)

5. **Probe Success Rate**
   ```
   avg by (organization, runner) (avg_over_time(probe_success{exporter="blackbox-exporter"}[5m])) * 100
   ```
   - `avg by`: Calculates average success rate by organization and runner
   - Purpose: Measures percentage of successful health endpoint probes from blackbox exporter

**Health Thresholds**

These thresholds are base and expected to be tuned in short term,

| Metric               | Healthy (Green) | Warning (Yellow) | Degraded (Orange) | Down (Red)    |
|----------------------|-----------------|------------------|-------------------|---------------|
| Cumulative Score     | 100%            | 99-99.9%         | 90-98.9%          | 0-89.9%       |

**Alerts**

The dashboard is connected to an alerting rule that triggers when any runner's cumulative health score falls below 100% for more than 5 minutes. The alert includes:
- Source: Panel ID 17 from the All Runners Health State dashboard
- Description: "Cumulative Runner Health Score is below the threshold for >5mins"
- Summary: "One or more runner components are not healthy"
- Labels: component=runner

**Interactive Features**

The dashboard includes interactive data links that allow operators to:
- Click on any runner's health score block to navigate to a detailed dashboard view for that specific runner
- View health score changes over time with the State Timeline visualization
- Filter and sort runners by organization, namespace, or component

The visualization changes color based on the thresholds defined above, providing immediate visual indication of health status.

**Future Enhancements**

1. A weighted version of the health score calculation allows assigning specific importance to each signal. Each signal's weight can be adjusted through Grafana variables, optimizing the dashboard for customized operational priorities.

Example of Proposed Base Weights Configuration (Draft Dashboard Available)

| Signal           | Recommended Weight |
|------------------|--------------------|
| HTTP Success     | 0.30               |
| Pod Restarts     | 0.25               |
| Probe Success    | 0.25               |
| Pod Ready Status | 0.20               |

2. Tune up threshold for cumulative score, more precision
   
| Score Range | Status   | Color  | Action                                |
|-------------|----------|--------|---------------------------------------|
| 95-100%     | Healthy  | Green  | Normal operations                     |
| 90-94.9%    | Warning  | Yellow | Monitor during next development cycle |
| 80-89.9%    | Degraded | Orange | Investigate when resources available  |
| <80%        | Critical | Red    | Prioritize investigation              |

These adjusted thresholds:
  - Provide more breathing room during development phases
  - Allow focusing resources on critical issues only
  - Still maintain visibility into system health
  - Better align with startup priorities (feature development vs perfect stability)

3. Split cumulative formula into set of separate, named health signals queries (not supported in currently running Grafana 10), then use in cumulative query along with weigh multiplies for readability and fine tune.

2. Consider individual thresholds for each score (?)

### Health Overview by Components
  
Detailed breakdown of health metrics by individual components for multiple runners.

- Multiple runner instances state
- Component version tracking
- Services status monitoring

| Metric (per 5m span) | Healthy (Green) | Warning (Yellow) | Degraded (Orange) | Down (Red)    |
|----------------------|-----------------|------------------|-------------------|---------------|
| Service Status       | 100%            | 95-100%          | 80-95%            | 0-80%         |
| Pod Restarts per     | 0-1 restarts    | 1.1-2 restarts   | 2.1-4 restarts    | >4.1 restarts |
| HTTP Success Rate    | 100%            | 95-99%           | 80-94%            | 0-79%         |
| Pod Status Ready     | 100%            | 90-99%           | 70-89%            | 0-69%         |

![Health Overview by Components](_docs/runner-health-overview-by-components.png)


### Runner Health Overview 
  
- Provides a comprehensive view of runner components' health status
- Filtering by organization, runner and namespace
- Component pods readiness status, restarts, health probes, etc.
- Component container running versions tracking
- Real-time health metrics visualization

| Metric (per 5m span) | Healthy (Green) | Warning (Yellow) | Degraded (Orange) | Down (Red)    |
|----------------------|-----------------|------------------|-------------------|---------------|
| Service Status       | 100%            | 95-100%          | 80-95%            | 0-80%         |
| Pod Restarts per     | 0-1 restarts    | 1.1-2 restarts   | 2.1-4 restarts    | >4.1 restarts |
| HTTP Success Rate    | 100%            | 95-99%           | 80-94%            | 0-79%         |
| Pod Status Ready     | 100%            | 90-99%           | 70-89%            | 0-69%         |

![Runner Health Overview](_docs/runner-health-overview-dashboard.png)

### Tool Manager Dashboard 

- Focused on Tool Manager performance metrics
- HTTP response time distribution
- Go runtime metrics (goroutines, threads, GC)
- Request/response statistics

![Health Overview by Components](_docs/tool-manager-dashboard.png)

### Agent Manager Dashboard 

- Monitors Agent Manager performance
- HTTP request metrics
- Error rate tracking
- Performance indicators

![Health Overview by Components](_docs/agent-manager-dashboard.png)

### Kubernetes State Dashboard 

(*Under development*)
 
- Provides Kubernetes state metrics for the runner namespace
- Based on `kube-state-metrics` data
- Includes summary metrics about the runner's Kubernetes resources

### Alloy Dashboard 

- Monitors Alloy pipelines
- Focus on Remote Writes to Prometheus (success/errors/count,...)
- Can show metrics flow for particular runner deployment (count/error/success/volume etc.
- Visualize targets it scrapes metrics from (count/error/success/volume etc.
- Can be used to control and on data alert spikes (and therefore cost) and broken metrics flow

![Health Overview by Components](_docs/alloy-dashboard.png)
 
### Blackbox Exporter Dashboards  

- Alternative visualization of HTTP probe metrics
- Focus on probe success rates and latencies
- SSL/TLS status monitoring
- DNS resolution performance
- Comprehensive HTTP request timing breakdown

![Blackbox Exporter Alternate View](_docs/blackbox-dashboard.png)
![Blackbox Dashboard](_docs/blackbox-alternate-dashboard.png)
 
## Dashboards as a Code

Initial set of dashboards are stored as code for future automatic provisioning into customer's Grafana instances, currently serving as version-controlled backups.

A dashboard export script is available at `kubiya-runner/_grafana-dashboards/grafana-dashboards-export.sh` for exporting dashboards from Azure Managed Grafana. When you create a new dashboard or modify an existing one, the recommended workflow is:

1. Use the export script to save the dashboard as a JSON file
2. Commit the file to the repository
3. Create a pull request to the main branch
4. Add more health signals: latency, saturation, scaling: expected vs desire replicas
5. Finalize Alloy dashboard
7. Separate helm value toggle for managed runners: implement add `node-exporter`, collect wider metrics with `kube-state-metrics`, add h/w metrics
8. Consider reframe into RED/USE/4GSignals
9. Connect Elasticsearch (or Loki) as a datasource for logs, get HTTP requests views and compound extra cumulative signals 


## K8s Resources Definitions

All resources defined in `values.yaml` are mandatory, but not yet set according to real consumption. All values must be reviewed and set based on average real usage statistics of from Grafana, with further tuning for particular deployments. Averages are expected as default values in next releases of this chart.

Apart from resource management goals, explicit resources may be mandatory for some particular deployments.
In such deployments pre-installed webhooks may deny installation of runner's k8s entities with unsatisfied requirements (restrictions) of particular target k8s cluster, and requests/limits are common example of such restrictions.

## Security

**Security Considerations:**

- Namespace-scoped RBAC permissions for components (except default required cluster-wide PVC management for `tool-manager` #TODO)
- Dedicated service accounts for each component 
- TLS support for registry communication (used by `tool-manager`)
- Reduced RBAC permissions for `Grafana Alloy` (namespace-scoped)
- Reduced RBAC permissions and targets for `kube-state-metrics` (namespace-scoped)

## Optional Permissions Extensions:

- `tool-manager`: optional cluster full access via `values.adminClusterRole.create`,
- Kubiya Operator full access toggle (controlled via values)
- Optional Dagger permissions

# Deployment

As of moment of writing this, default configuration set via `values.yaml` should support most of the regular deployments. However, there are list of variables specific to each particular deployment, as well as list of secrets which must be configured before installing this chart.

## Minimum Required Configuration & Values Passing

Values below can be considered as non-mutable secrets, unique for each runner deployment.

- `alloy.alloy.extraENV` all env vars must be set for support of metrics push to remote Prometheus via remote writes (see [Azure Prometheus Integration](#azure-prometheus-integration))
- `organization`: "my_organization" - given organization name
- `uuid`: "679adc53-7068-4454-aa9f-16df30b14a50" - UUID of the agent
- `nats.jwt` and `nats.secondJwt`: NATS credentials for sending metrics to NATS Cloud (Synadia). Tokens are generated by kubiya frontend UI with frontend-specific runner name encoded as a part of token.
- `nats.subject`: NATS destination subject for metrics sending
- `nats.serverUrl`: NATS server URL

These requirements are present in a structured way in template file `_deploymentX-values-overrides.yaml` and expected to be in sync with requirements of current chart version. 
Instead of passing values to helm install if form of `-set xxx=yyy`, it is highly recommended making a copy of this file as overrides base for a new deployment, and after installation keep it in safe, dry place for future purposes (upgrades, etc.)

## Installation

 *IMPORTANT* Runner name will be set to the release name by default (`deploymentX` in example cmd below).
 If not overriden (see below) release name must match runner's name encoded in JWT token which set in `nats.*` values.

```shell
helm install deploymentX . -f values.yaml -f _deploymentX-values-overrides.yaml --namespace kubiya --create-namespace
```

## Update

```shell
helm upgrade deploymentX . -f values.yaml -f _deploymentX-values-overrides.yaml --namespace kubiya
``` 

## Using Name Overrides

`runnerNameOverride` if used, must match the JWT token for NATS communication. 

In some special cases there are name overrides values available to override runner name

If `helm install my-release ./kubiya-runner:` used for installation, then:
- If `runnerNameOverride`: "my-metrics-test":
  - name = *my-metrics-test*
  - fullname = *my-metrics-test*
  - All resources will use this name

- If no `runnerNameOverride` but `nameOverride`: "custom":
  - name = *custom*
  - fullname = *my-release-custom*

- If no `runnerNameOverride` but `fullnameOverride`: "full-custom":
  - name = Chart.Name or `nameOverride`
  - fullname = *full-custom*

- If no overrides:
  - name = Chart.Name
  - fullname = *my-release-kubiya-runner*

## Environment Variables Management

The chart uses a consistent pattern for managing environment variables across all components. Each component that requires environment variables has the following structure in values.yaml:

```yaml
componentName:
  env:
    # Default required env vars that should not be removed
    defaults:
      ENV_VAR_1: "value1"
      ENV_VAR_2: "value2"
      SECRET_VAR:
        valueFrom:
          secretKeyRef:
            name: secret-name
            key: secret-key
    # Custom additional env vars that can be added without modifying templates
    custom: {}
```

### Adding Custom Environment Variables

You can add custom environment variables to any component without modifying the templates by using your own values file:

```yaml
# custom-values.yaml
enforcer:
    env:
      custom:
        MY_CUSTOM_VAR: "custom_value"
        MY_SECRET_VAR:
          valueFrom:
            secretKeyRef:
              name: my-secret
              key: my-key

toolManager:
  env:
    custom:
      ADDITIONAL_VAR: "some-value"
```

### Components Supporting Environment Variables

The following components support the environment variables pattern:

- Enforcer
  - Main container
  - PostgreSQL container
  - OPAL Server container
  - OPAL Client container
- Tool Manager
  - Main container
  - SDK Server container
- Agent Manager
- Kubiya Operator

### Environment Variables Features

- Supports both simple string values and complex valueFrom references
- Maintains required default variables while allowing custom additions
- Uses template interpolation via the tpl function
- Preserves all default required env vars when adding custom ones
- Follows Kubernetes best practices for secret references

### Example: Adding Environment Variables

Here's an example of how to add environment variables to multiple components:

```yaml
# values.yaml
enforcer:
  env:
    custom:
      NEW_FEATURE_FLAG: "true"
      API_KEY:
        valueFrom:
          secretKeyRef:
            name: api-secrets
            key: api-key

toolManager:
  env:
    custom:
      CUSTOM_ENDPOINT: "https://api.example.com"
      DEBUG_MODE: "true"

agentManager:
  env:
    custom:
      MONITORING_ENABLED: "true"
```

### Notes

- Default environment variables are required for component functionality and should not be removed
- Custom environment variables are merged with defaults, not replacing them
- All components support both simple values and valueFrom references
- Template interpolation is available in both default and custom variables
- Environment variables can reference other values using the standard Helm templating syntax
