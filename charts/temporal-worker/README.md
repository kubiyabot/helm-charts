# Temporal Worker Helm Chart

A Helm chart for deploying the Kubiya Temporal Worker service - a **background job processor and Temporal API bridge**.

## Overview

The Temporal Worker serves two key purposes:

- **REST API Bridge** - Exposes REST endpoints for managing Temporal workflows, enabling HTTP-based workflow control
- **Background Job Processing** - Executes long-running workflows that call back to the Control Plane API

Key capabilities:
- Start, query, signal, and cancel Temporal workflows via REST API
- Execute `ExecutionPromptWorkflow` for agent task processing
- Handle async operations that would timeout in synchronous API calls
- Provide workflow state visibility and history access

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      TEMPORAL WORKER                           │
├──────────────────────────────┬─────────────────────────────────┤
│         API SERVER           │           WORKER                │
│  ┌────────────────────────┐  │  ┌───────────────────────────┐  │
│  │   REST API (8000)      │  │  │   Temporal Activity       │  │
│  │                        │  │  │      Worker               │  │
│  │  Workflow management   │  │  │                           │  │
│  │  • Start/stop/signal   │  │  │  Executes workflows:      │  │
│  │  • Query/list          │  │  │  • ExecutionPromptWF      │  │
│  │                        │  │  │  • Background tasks       │  │
│  │  Health endpoints      │  │  │                           │  │
│  │  • /health, /ready     │  │  │  Calls Control Plane API  │  │
│  │                        │  │  │  for actual processing    │  │
│  └────────────────────────┘  │  └───────────────────────────┘  │
└──────────────────────────────┴─────────────────────────────────┘
        │                                      │
        ▼                                      ▼
┌───────────────────┐              ┌───────────────────┐
│     Temporal      │              │   Control Plane   │
│     Server        │              │       API         │
└───────────────────┘              └───────────────────┘
```

The application is split into two distinct deployment components to allow for independent scaling and isolation of concerns.

### 1. API Service
*   **Role**: Exposes REST endpoints for workflow management and system health.
*   **Networking**: Exposes port `8000` (ClusterIP).
*   **Probes**: configured with Liveness (`/health`) and Readiness (`/ready`) checks to ensure traffic is only routed to healthy pods.
*   **Command**: `uvicorn temporal_app.api.main:app ...`

### 2. Worker Service
*   **Role**: Background worker that polls the Temporal Task Queue to execute workflows and activities.
*   **Networking**: Does **not** expose any ports. It relies on outbound connections (long-polling) to the Temporal Server.
*   **Probes**: Disabled by default as the worker does not run an HTTP server.
*   **Command**: `python -m temporal_app.worker`

## Installation

```bash
# Install from OCI Registry
helm upgrade --install temporal-worker oci://ghcr.io/kubiyabot/charts/temporal-worker \
  --version 0.1.0 \
  --namespace kubiya \
  --create-namespace
```

## Configuration

### Global Configuration

This chart supports global configuration that is shared across all charts in the stack:

```yaml
global:
  environment: "production"
  logLevel: "INFO"
  existingSecret: "my-shared-secrets"  # Optional: secret injected into all components
```

### Values Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `control-plane-temporal` |
| `image.tag` | Image tag (defaults to appVersion) | `""` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets | `[]` |
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override full release name | `""` |
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |
| `podAnnotations` | Pod annotations | `{}` |
| `podSecurityContext` | Pod security context | `{}` |
| `securityContext` | Container security context | `{}` |
| `env` | Environment variables (map format) | See below |
| `envFrom` | Global Secret/ConfigMap references | See default |
| `api.enabled` | Enable API deployment | `true` |
| `api.replicaCount` | API replicas | `1` |
| `api.service.type` | Service type | `ClusterIP` |
| `api.service.port` | Service port | `80` |
| `api.service.targetPort` | Container port | `8000` |
| `api.resources.limits.cpu` | API CPU limit | `1000m` |
| `api.resources.limits.memory` | API memory limit | `1Gi` |
| `api.resources.requests.cpu` | API CPU request | `500m` |
| `api.resources.requests.memory` | API memory request | `512Mi` |
| `api.livenessProbe.*` | Liveness probe config | See values.yaml |
| `api.readinessProbe.*` | Readiness probe config | See values.yaml |
| `api.envFrom` | API-specific secrets | `[]` |
| `api.ingress.enabled` | Enable ingress | `false` |
| `api.ingress.className` | Ingress class | `nginx` |
| `api.ingress.host` | Ingress host | `control-plane-temporal.example.com` |
| `api.pdb.enabled` | Enable PDB | `true` |
| `api.pdb.maxUnavailable` | PDB max unavailable | `1` |
| `worker.enabled` | Enable Worker deployment | `true` |
| `worker.replicaCount` | Worker replicas | `1` |
| `worker.resources.limits.cpu` | Worker CPU limit | `1000m` |
| `worker.resources.limits.memory` | Worker memory limit | `1Gi` |
| `worker.resources.requests.cpu` | Worker CPU request | `500m` |
| `worker.resources.requests.memory` | Worker memory request | `512Mi` |
| `worker.envFrom` | Worker-specific secrets | `[]` |
| `worker.pdb.enabled` | Enable PDB | `true` |
| `worker.pdb.maxUnavailable` | PDB max unavailable | `1` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Pod tolerations | `[]` |
| `affinity` | Pod affinity (anti-affinity by default) | See values.yaml |

### Environment Variables

Environment variables are sourced from three places:

**1. Hardcoded in templates (static, cannot be changed):**

| Variable | Value | Reason |
|----------|-------|--------|
| `PYTHONUNBUFFERED` | `"1"` | Python framework requirement |

**2. Configurable via `env` in values.yaml:**

| Variable | Description | Default |
|----------|-------------|---------|
| `TEMPORAL_NAMESPACE` | Temporal namespace | `default` |
| `TASK_QUEUE` | Temporal task queue name | `background-jobs` |
| `MAX_CONCURRENT_ACTIVITIES` | Max concurrent activity executions | `10` |
| `MAX_CONCURRENT_WORKFLOW_TASKS` | Max concurrent workflow tasks | `10` |
| `LOG_LEVEL` | Logging level (DEBUG, INFO, WARNING, ERROR) | `INFO` (from global) |
| `LOG_FORMAT` | Log format (`json` or `console`) | `json` |
| `ENVIRONMENT` | Deployment environment | `production` (from global) |

**3. Required via secrets (envFrom):**

See [Required Secrets](#required-secrets) section above.

### Mode Selection
You can enable or disable components using values:

```yaml
# Only deploy Worker
api:
  enabled: false
worker:
  enabled: true
```

## Dependencies

The Temporal Worker requires the following external services:

| Service | Purpose | Required |
|---------|---------|----------|
| Temporal Server | Workflow orchestration backend | Yes |
| Control Plane API | Agent execution callbacks | Yes |
| LiteLLM Proxy | LLM access for workflow activities | No |
| Context Graph API | Memory/knowledge graph access | No |

## Required Secrets

This chart expects secrets to be created externally and referenced via `envFrom`. Create a secret with the following keys:

```bash
kubectl create secret generic temporal-worker-secrets \
  --namespace kubiya \
  --from-literal=TEMPORAL_HOST="temporal-frontend:7233" \
  --from-literal=TEMPORAL_NAMESPACE="default" \
  --from-literal=TEMPORAL_API_KEY="your-temporal-api-key" \
  --from-literal=KUBIYA_API_KEY="your-kubiya-api-key" \
  --from-literal=CONTROL_PLANE_API_URL="http://control-plane-api:80" \
  --from-literal=GRAPH_API_URL="http://context-graph-api:80" \
  --from-literal=LITELLM_API_BASE="http://litellm:4000" \
  --from-literal=LITELLM_API_KEY="your-litellm-api-key"
```

### Environment Variables Reference

| Variable | Description | Required |
|----------|-------------|----------|
| `TEMPORAL_HOST` | Temporal frontend address | Yes |
| `TEMPORAL_NAMESPACE` | Temporal namespace | Yes |
| `TEMPORAL_API_KEY` | Temporal Cloud API key (if using cloud) | No |
| `KUBIYA_API_KEY` | Internal Kubiya API key | Yes |
| `CONTROL_PLANE_API_URL` | Control Plane API URL for callbacks | Auto |
| `GRAPH_API_URL` | Context Graph API URL | Auto |
| `LITELLM_API_BASE` | LiteLLM proxy base URL | Auto |
| `LITELLM_API_KEY` | LiteLLM API key | No |

*Note: `CONTROL_PLANE_API_URL`, `GRAPH_API_URL` and `LITELLM_API_BASE` are automatically configured via smart service discovery defaults but can be overridden in `env`.*

### Worker Configuration Variables

These are set in `values.yaml` under `env`:

| Variable | Description | Default |
|----------|-------------|---------|
| `TASK_QUEUE` | Temporal task queue name | `background-jobs` |
| `MAX_CONCURRENT_ACTIVITIES` | Max concurrent activity executions | `10` |
| `MAX_CONCURRENT_WORKFLOW_TASKS` | Max concurrent workflow tasks | `10` |
| `LOG_LEVEL` | Logging level | `INFO` |
| `LOG_FORMAT` | Log format (`json` or `console`) | `json` |

Then reference it in your values:

```yaml
envFrom:
  - secretRef:
      name: temporal-worker-secrets
```

Component-specific secrets can also be added via `api.envFrom` or `worker.envFrom`.

## High Availability

### Pod Disruption Budgets

PDBs are enabled by default and created when `replicaCount > 1`. They use `maxUnavailable: 1` by default.

**WARNING: Common PDB Pitfalls**

| Misconfiguration | Problem |
|------------------|---------|
| `minAvailable >= replicaCount` | Pods become undrainable. Node upgrades will hang. |
| `replicaCount: 1` with PDB | PDB is useless (math requires 2+ replicas). Template auto-disables. |
| PDB + HPA + Cluster Autoscaler | Can deadlock if `minAvailable` equals HPA `minReplicas`. Use `maxUnavailable` instead. |

**Safe configuration:**

```yaml
api:
  replicaCount: 2
  pdb:
    enabled: true
    maxUnavailable: 1  # Safe: always allows draining 1 pod

worker:
  replicaCount: 2
  pdb:
    enabled: true
    maxUnavailable: 1
```

### Pod Anti-Affinity

Enabled by default to spread replicas across nodes. One node failure won't take down all replicas.
