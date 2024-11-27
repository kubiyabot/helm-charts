# Kubiya Runner

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/kubiya-helm-charts)](https://artifacthub.io/packages/search?repo=kubiya-helm-charts)

A Helm chart for deploying the Kubiya Runner.

## Table of Contents

- [Kubiya Runner](#kubiya-runner)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Directory Structure](#directory-structure)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Permissions](#permissions)
  - [Components](#components)
    - [Agent Manager](#agent-manager)
    - [Kubiya Operator](#kubiya-operator)
    - [Tool Manager](#tool-manager)
    - [Image Updater](#image-updater)
  - [Dependencies \& Compatibility Matrix](#dependencies--compatibility-matrix)
    - [Helm Dependencies](#helm-dependencies)
    - [Container Images](#container-images)
  - [Monitoring \& Telemetry](#monitoring--telemetry)
  - [K8s Resources Definitions](#k8s-resources-definitions)
  - [Security](#security)
  - [Optional Permissions Extensions:](#optional-permissions-extensions)
  - [Installation](#installation-1)
  - [Minimum Required Configuration](#minimum-required-configuration)
  - [Using Name Overrides](#using-name-overrides)

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
│   ├── dagger-engine-headless-service.yaml        # Dagger suplimental headless service
│   ├── otel-collector-configMap.yaml              # otel-collector configuration
│   └── secrets.yaml                               # Secrets shared between runner components
└── charts/                                        # Dependencies (subcharts)
    ├── dagger-helm/                               # Container runtime for workflows
    ├── kube-state-metrics/                        # Cluster-level metrics
    └── opentelemetry-collector/                   # Telemetry collection
```

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure
- NATS credentials for messaging
- Registry TLS certificates (if using private registry)

## Installation

```bash
# Add the Kubiya Helm repository
helm repo add kubiya https://kubiyabot.github.io/helm-charts

# Update your Helm repositories
helm repo update

# Install the chart
helm install my-release kubiya/kubiya-runner
```

## Permissions


## Components

### Agent Manager

Repository: [kubiya-agent-manager](https://github.com/kubiyabot/kubiya-agent-manager)

[#TODO: Needs documentation]

### Kubiya Operator

Repository: [kubiya-operator](https://github.com/kubiyabot/kubiya-operator)

[#TODO: Needs documentation]

### Tool Manager

The Kubiya Tool Manager is a high-performance, container-native utility designed for declarative management and execution of agent tools across diverse computing environments. It provides a scalable, stateless architecture for tool orchestration, supporting both local development and enterprise-scale Kubernetes deployments.

Full documentation is available [in project repository](https://github.com/kubiyabot/tool-manager).

- Executes tools within the cluster
- Integrates with Dagger for container runtime
- Includes SDK server for tool execution

### Image Updater

- Checks for updates of latest stable image versions via CronJob (hourly by default).
- Automatic updates for runner components (agent-manager, tool-manager, sdk-server) from stable release JSON file hosted in [S3 bucket](https://kubiya-cli.s3.amazonaws.com/stable/kubiya_versions.json).

## Dependencies & Compatibility Matrix

This version of this chart as of version 0.3.0 is tested to be compatible with the following versions of container images and Helm dependencies.

### Helm Dependencies

| Chart | Version |
|-------|---------|
| dagger-helm | 0.13.6 |
| kube-state-metrics | 5.27.0 |
| opentelemetry-collector | 0.109.0 |

### Container Images

| Component | Image | Version/Tag |
|-----------|-------|-------------|
| Agent Manager | ghcr.io/kubiyabot/agent-manager | 0.0.17 |
| Kubiya Operator | ghcr.io/kubiyabot/kubiya-operator | runner_v2 |
| Tool Manager | ghcr.io/kubiyabot/tool-manager | 462d60470b8f8063bac9c11887dc3620a71b8c56 |
| SDK Server | ghcr.io/kubiyabot/sdk-py | v0.47.1 |
| Image Updater | bitnami/kubectl | 1.30.6 |
| OpenTelemetry Collector | ghcr.io/kubiyabot/otel-connector | release-0.1.1 |
| Dagger Engine | ghcr.io/kubiyabot/kubiya-registry | v0.1.1 |
| Kube State Metrics | registry.k8s.io/kube-state-metrics/kube-state-metrics | 2.14.0 |

## Monitoring & Telemetry

The chart includes comprehensive monitoring setup:
- `otel-collector` for metrics and traces collection, processing and sending. Utilize [non-oficial container image](https://github.com/kubiyabot/otel-collector) built with custom implementation of `nats-exporter` exporter plugin which send collected data to NATS Cloud (Synadia).
- `kube-state-metrics` for Kubernetes metrics. Configured to be limited to collect metrics only for single namespace of Runner deployment due to security concerns for client side deployment scenarios.
- Metrics are labeled with 'organization' and 'cluster' labels to allow deployment filtering and grouping; configured via `values.yaml` for particular deployment.

## K8s Resources Definitions

All resources defined in `values.yaml` are mandatory, but not yet set according to real consumption. All values must be reviewed and set based on average real usage statistics of from Grafana, with further tuning for particular deployments. Averages are expected as default values in next releases of this chart.

Apart from resource management goals, explicit resources may be mandatory for some particular deployments.
In such deployments pre-installed webhooks may deny installation of runner's k8s entities with unsatisfied requirements (restrictions) of particular target k8s cluster, and requests/limits are common example of such restrictions.


## Security

*[Under Development]*
- Namespace-scoped RBAC permissions
- Service accounts for each component
- TLS support for registry communication (used by `tool-manager`)

## Optional Permissions Extensions:

*[Under Development]*
- Kubiya Operator full access toggle (controlled via values)
- Custom OpenTelemetry roles
- Optional Dagger permissions


## Installation

As of moment of writing this, default configuration set via `values.yaml` should support most of the regular deployments. However, there are list of variables specific to each particular deployment, as well as list of secrets which must be configured before installing this chart.

## Minimum Required Configuration

- `runnerNameOverride`: This can be used to override default runner name generated from release name. 
  *IMPORTANT* Runner name must match one encoded in JWT token configured in `nats.*` values. Propagated via config map of `otel-collector` name will be used for labeling metrics which will be send by custom `nats-exporter` plugin to NATS/Synadia. Name mismatch between one set here (or generated from release name if not set) and the one encoded in JWT token will break communication causing NATS rejects.
- `organization`: "my_organization" - given organization name
- `kubiyaAgentUUID`: "679adc53-7068-4454-aa9f-16df30b14a50" - UUID of the agent
- `nats.jwt` and `secondJwt`: NATS credentials for sending metrics to NATS Cloud (Synadia). Tokens are generated by kubiya frontend UI with frontend-specific runner name encoded as a part of token.
- `nats.subject`: NATS destination subject for metrics sending
- `nats.serverUrl`: NATS server URL
- `registryTls.crt` and `registryTls.key`: TLS certificates for private registry (used by `tool-manager`) 


## Using Name Overrides

The current implementation has a specific purpose: `runnerNameOverride` is critical because it must match the JWT token for NATS communication.

Example of naming variable overrides available when installing chart release. 

If `helm install my-release ./kubiya-runner:` used for installation, then:
- If `runnerNameOverride`: "sergey-metrics-test":
  - name = *sergey-metrics-test*
  - fullname = *sergey-metrics-test*
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

