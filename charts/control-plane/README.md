# Control Plane Helm Chart

A Helm chart for deploying the Kubiya Control Plane service - a **multi-tenant AI agent orchestration platform**.

## Overview

The Control Plane is the brain of the Kubiya platform, providing:

- **Agent Management** - Create, configure, and manage AI agents
- **Team Orchestration** - Coordinate multiple agents working together
- **Workflow Engine** - Execute complex multi-step workflows via Temporal
- **Job Scheduling** - Cron jobs and webhook-triggered automation
- **Real-time Streaming** - WebSocket-based execution streaming
- **Skills & Tools** - Extensible capabilities for agents
- **Policy Enforcement** - Access control and security policies
- **Analytics** - Usage tracking and insights

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                       CONTROL PLANE                            │
├──────────────────────────────┬─────────────────────────────────┤
│         API SERVER           │           WORKER                │
│  ┌────────────────────────┐  │  ┌───────────────────────────┐  │
│  │    REST API (7777)     │  │  │   Temporal Worker Client  │  │
│  │                        │  │  │                           │  │
│  │  Agent & Team APIs     │  │  │   Processes queued jobs   │  │
│  │  Workflow & Job APIs   │  │  │   from Temporal server    │  │
│  │  Execution APIs        │  │  │   from Temporal server    │  │
│  │  Skills & Policy APIs  │  │  └───────────────────────────┘  │
│  └────────────────────────┘  │                                 │
│                              │  ┌───────────────────────────┐  │
│  ┌────────────────────────┐  │  │   Background Processors   │  │
│  │   WebSocket Server     │  │  │   • Queue consumers       │  │
│  │   (execution streams)  │  │  │   • Event handlers        │  │
│  └────────────────────────┘  │  └───────────────────────────┘  │
└──────────────────────────────┴─────────────────────────────────┘
        │                                      │
        ▼                                      ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────────┐
│  PostgreSQL   │  │     Redis     │  │     Temporal      │
│  (pgvector)   │  │ (Cache/PubSub)│  │  (Orchestration)  │
└───────────────┘  └───────────────┘  └───────────────────┘
```

The application is split into two distinct deployment components:

### API Service
- **Role**: REST API for user interactions and system management
- **Port**: 7777 (ClusterIP)
- **Health**: `/api/health` endpoint

### Worker Service
- **Role**: Background task processor for queue-based jobs
- **Networking**: No exposed ports (internal processing only)
- **Command**: `python scripts/seed_worker_queues.py && python control_plane_api/worker/worker.py`

## Installation

```bash
helm install control-plane ./control-plane \
  --namespace kubiya \
  --create-namespace
```

## Dependencies

The Control Plane requires the following external services:

| Service               | Purpose                                       | Required |
| --------------------- | --------------------------------------------- | -------- |
| PostgreSQL (pgvector) | Primary database for agents, users, workflows | Yes      |
| Redis                 | Cache, session storage, pub/sub events        | Yes      |
| Temporal              | Workflow orchestration engine                 | Yes      |
| LLM Provider          | AI model access (OpenAI, LiteLLM proxy)       | Yes      |

## Required Secrets

This chart expects secrets to be created externally and referenced via `envFrom`. Create a secret with the following keys:

```bash
kubectl create secret generic control-plane-secrets \
  --namespace kubiya \
  --from-literal=DATABASE_URL="postgresql://user:password@host:5432/agent_control_plane" \
  --from-literal=REDIS_URL="redis://redis:6379/0" \
  --from-literal=SECRET_KEY="your-secret-key" \
  --from-literal=JWT_SECRET="your-jwt-secret" \
  --from-literal=OPENAI_API_KEY="your-openai-key" \
  --from-literal=TEMPORAL_HOST="temporal-frontend:7233" \
  --from-literal=TEMPORAL_NAMESPACE="default" \
  --from-literal=KUBIYA_API_KEY="your-kubiya-api-key"
```

### Environment Variables Reference

| Variable             | Description                       | Required |
| -------------------- | --------------------------------- | -------- |
| `DATABASE_URL`       | PostgreSQL connection string      | Yes      |
| `REDIS_URL`          | Redis connection string           | Yes      |
| `SECRET_KEY`         | Application secret for encryption | Yes      |
| `JWT_SECRET`         | JWT signing secret                | Yes      |
| `TEMPORAL_HOST`      | Temporal frontend address         | Yes      |
| `TEMPORAL_NAMESPACE` | Temporal namespace                | Yes      |
| `OPENAI_API_KEY`     | OpenAI API key (or LiteLLM key)   | Yes      |
| `KUBIYA_API_KEY`     | Internal Kubiya API key           | No       |
| `GRAPH_API_URL`      | Context Graph API URL             | Auto     |
| `LITELLM_API_BASE`   | LiteLLM proxy base URL            | Auto     |
| `WEBSOCKET_ENABLED`  | Enable WebSocket support          | No       |

*Note: `GRAPH_API_URL` and `LITELLM_API_BASE` are automatically configured via smart service discovery defaults but can be overridden in `env`.*

### NATS Event Bus (Optional)

For high-performance event delivery, the Control Plane supports NATS as an optional event bus provider:

| Variable | Description | Default |
|----------|-------------|---------|
| `NATS_ENABLED` | Enable NATS event bus provider | `false` |
| `NATS_URL` | NATS server URL | `nats://nats:4222` |
| `NATS_OPERATOR_JWT` | NATS operator JWT credential | - |
| `NATS_OPERATOR_SEED` | NATS operator seed credential | - |

**Performance comparison** (vs HTTP baseline):
- WebSocket: ~50% latency reduction
- Redis: ~70% latency reduction
- NATS: ~80-90% latency reduction

All providers run in parallel; at least one must succeed.

### Observability (OpenTelemetry)

The Control Plane supports distributed tracing via OpenTelemetry. Add these to your secrets to enable:

| Variable | Description | Default |
|----------|-------------|---------|
| `OTEL_ENABLED` | Enable OpenTelemetry tracing | `true` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP collector endpoint (e.g., `http://otel-collector:4317`) | None (tracing disabled if not set) |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | Export protocol: `grpc` or `http` | `grpc` |
| `OTEL_SERVICE_NAME` | Service name in traces | `agent-control-plane` |
| `OTEL_RESOURCE_ATTRIBUTES` | Additional attributes (e.g., `deployment.environment=production`) | `""` |
| `OTEL_TRACES_SAMPLER` | Sampling strategy | `parentbased_always_on` |
| `OTEL_TRACES_SAMPLER_ARG` | Sampler argument (e.g., `0.1` for 10% sampling) | None |

**Sampling strategies:**
- `always_on` / `always_off` - Trace all or none
- `parentbased_always_on` - Follow parent decision, default to on
- `parentbased_traceidratio` - Follow parent, sample ratio for new traces
- `traceidratio` - Sample by ratio (ignores parent)

**Example configuration:**

```yaml
env:
  OTEL_ENABLED: "true"
  OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector:4317"
  OTEL_SERVICE_NAME: "control-plane"
  OTEL_RESOURCE_ATTRIBUTES: "deployment.environment=production,service.version=1.0.0"
  OTEL_TRACES_SAMPLER: "parentbased_traceidratio"
  OTEL_TRACES_SAMPLER_ARG: "0.1"  # 10% sampling
```

Then reference it in your values:

```yaml
envFrom:
  - secretRef:
      name: control-plane-secrets
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
| `image.repository` | Image repository | `ghcr.io/kubiyabot/control-plane` |
| `image.tag` | Image tag (defaults to appVersion) | `""` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets | `[]` |
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override full release name | `""` |
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |
| `podAnnotations` | Pod annotations | Prometheus scraping |
| `podSecurityContext` | Pod security context | `{}` |
| `securityContext` | Container security context | `{}` |
| `otel.serviceName` | OTEL service name (default: derived from release) | `""` |
| `otel.resourceAttributes` | OTEL resource attributes (default: derived) | `""` |
| `env` | Environment variables (map format) | See below |
| `envFrom` | Secret/ConfigMap references | `[]` |
| `api.enabled` | Enable API deployment | `true` |
| `api.replicaCount` | API replicas | `2` |
| `api.service.type` | Service type | `ClusterIP` |
| `api.service.port` | Service port | `80` |
| `api.service.targetPort` | Container port | `7777` |
| `api.service.sessionAffinity` | Session affinity for WebSocket | `ClientIP` |
| `api.resources.limits.cpu` | API CPU limit | `1000m` |
| `api.resources.limits.memory` | API memory limit | `1Gi` |
| `api.resources.requests.cpu` | API CPU request | `500m` |
| `api.resources.requests.memory` | API memory request | `512Mi` |
| `api.livenessProbe.*` | Liveness probe config | See values.yaml |
| `api.readinessProbe.*` | Readiness probe config | See values.yaml |
| `api.ingress.enabled` | Enable ingress | `false` |
| `api.ingress.className` | Ingress class | `nginx` |
| `api.ingress.host` | Ingress host | `control-plane.example.com` |
| `api.autoscaling.enabled` | Enable HPA | `false` |
| `api.autoscaling.minReplicas` | HPA min replicas | `2` |
| `api.autoscaling.maxReplicas` | HPA max replicas | `10` |
| `api.pdb.enabled` | Enable PDB | `true` |
| `api.pdb.maxUnavailable` | PDB max unavailable | `1` |
| `worker.enabled` | Enable Worker deployment | `true` |
| `worker.replicaCount` | Worker replicas | `2` |
| `worker.resources.limits.cpu` | Worker CPU limit | `2000m` |
| `worker.resources.limits.memory` | Worker memory limit | `2Gi` |
| `worker.resources.requests.cpu` | Worker CPU request | `1000m` |
| `worker.resources.requests.memory` | Worker memory request | `1Gi` |
| `worker.autoscaling.enabled` | Enable HPA | `false` |
| `worker.pdb.enabled` | Enable PDB | `true` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Pod tolerations | `[]` |
| `affinity` | Pod affinity (anti-affinity by default) | See values.yaml |

### Environment Variables

Environment variables are sourced from three places:

**1. Hardcoded in templates (static, cannot be changed):**

| Variable | Value | Reason |
|----------|-------|--------|
| `PYTHONUNBUFFERED` | `"1"` | Python framework requirement |
| `OTEL_SERVICE_NAME` | Derived from release | `{{ .Release.Name }}-control-plane` |
| `OTEL_RESOURCE_ATTRIBUTES` | Derived from release | `service.name={{ .Release.Name }}-control-plane` |

**2. Configurable via `env` in values.yaml:**

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | Deployment environment | `production` (from global) |
| `LOG_LEVEL` | Log level (DEBUG, INFO, WARNING, ERROR) | `INFO` (from global) |
| `WEBSOCKET_ENABLED` | Enable WebSocket support | `true` |

**3. Required via secrets (envFrom):**

See [Required Secrets](#required-secrets) section above.

### Overriding OTEL Configuration

By default, OTEL service name is derived from the release name. To override:

```yaml
# values.yaml
otel:
  serviceName: "my-custom-service-name"
  resourceAttributes: "service.name=my-custom-service,env=prod"
```

Or via `--set`:

```bash
helm install control-plane ./control-plane \
  --set otel.serviceName="my-service" \
  --set otel.resourceAttributes="service.name=my-service,env=prod"
```

## Mode Selection

Deploy only specific components:

```yaml
# Only deploy API
api:
  enabled: true
worker:
  enabled: false
```

```yaml
# Only deploy Worker
api:
  enabled: false
worker:
  enabled: true
```

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
  replicaCount: 3
  pdb:
    enabled: true
    maxUnavailable: 1  # Safe: always allows draining 1 pod
    # minAvailable: 2  # Alternative, but riskier with HPA

worker:
  replicaCount: 4
  pdb:
    enabled: true
    maxUnavailable: 1
```

### Pod Anti-Affinity

Enabled by default to spread replicas across nodes. One node failure won't take down all replicas.

## Upgrading

```bash
helm upgrade control-plane ./control-plane \
  --namespace kubiya
```

## Uninstalling

```bash
helm uninstall control-plane --namespace kubiya
```
