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
  - [Components](#components)
    - [Agent Manager](#agent-manager)
    - [Kubiya Operator](#kubiya-operator)
    - [Tool Manager](#tool-manager)
    - [Image Updater](#image-updater)
  - [Dependencies](#dependencies)
  - [Monitoring \& Telemetry](#monitoring--telemetry)
  - [Security](#security)
  - [Configuration (values.yaml)](#configuration-valuesyaml)

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

## Components

### Agent Manager

Handles the lifecycle of Kubiya agents, including:

- Agent provisioning
- Health monitoring
- Resource management

### Kubiya Operator

- Controls operational aspects of the runner
- Manages workflow orchestration
- Handles state management
- Single replica deployment

### Tool Manager

The Kubiya Tool Manager is a high-performance, container-native utility designed for declarative management and execution of agent tools across diverse computing environments. It provides a scalable, stateless architecture for tool orchestration, supporting both local development and enterprise-scale Kubernetes deployments.

Full documentation is available [in project repository](https://github.com/kubiyabot/tool-manager).

- Executes tools within the cluster
- Integrates with Dagger for container runtime
- Includes SDK server for tool execution

### Image Updater
- Automatic updates for runner components
- Runs as a CronJob (hourly by default)
- Updates deployments with latest stable images

## Dependencies

The chart includes the following dependencies:

| Name | Version | Description |
|------|---------|-------------|
| dagger-helm | 0.13.6 | Container runtime for workflows |
| kube-state-metrics | 5.27.0 | Kubernetes cluster metrics collection |
| opentelemetry-collector | 0.109.0 | Telemetry and metrics collection |

## Monitoring & Telemetry

The chart includes comprehensive monitoring setup:
- `otel-collector` for metrics and traces collection, processing and sending. Utilize [non-oficial container image](https://github.com/kubiyabot/otel-collector) built with custom implementation of `nats-exporter` exporter plugin which send collected data to NATS Cloud (Synadia).
- `kube-state-metrics` for Kubernetes metrics. Configured to be limited to collect metrics only for single namespace of Runner deployment due to security concerns for client side deployment scenarios.
- Metrics are labeled with 'organization' and 'cluster' labels to allow deployment filtering and grouping; configured via `values.yaml` for particular deployment.

## Security

- Namespace-scoped RBAC permissions
- Service accounts for each component
- TLS support for registry communication
- Secure secrets management

## Configuration (values.yaml)

As of moment of writing this, default configuration set via `values.yaml` should support most of the regular deployments. However, there are list of variables specific to each particular deployment, as well as list of secrets which must be configured before installing this chart:

- `organization`: "my_organization" - given organization name
- `kubiyaAgentUUID`: "679adc53-7068-4454-aa9f-16df30b14a50" - UUID of the agent`
- `nats.jwt` and `nats.secondJwt`: NATS credentials for sending metrics to NATS Cloud (Synadia)
- `nats.subject`: NATS destination subject for metrics sending
- `registryTls.crt` and `registryTls.key`: TLS certificates for private registry (if used)
