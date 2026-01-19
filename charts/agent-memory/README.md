# Agent Memory Helm Chart

A Helm chart for deploying the Kubiya Agent Memory service (formerly Context Graph) - a **cognitive memory and knowledge graph service** for AI agents.

## Overview

The Agent Memory service provides long-term memory and knowledge management capabilities for AI agents:

- **Knowledge Graph** - Neo4j-based graph database for entity relationships
- **Semantic Search** - Vector similarity search using pgvector embeddings
- **Memory Storage** - Persistent memory for agent conversations and context
- **Knowledge Extraction** - AI-powered entity and relationship extraction
- **Dataset Management** - Organize and query knowledge datasets
- **Multi-tenant Isolation** - Organization and integration-level namespacing

Key capabilities:
- Store and retrieve agent memories with semantic similarity
- Build knowledge graphs from unstructured data
- Perform intelligent search across memories and knowledge
- Configure cognitive processing pipelines per organization
- RBAC and audit logging for enterprise deployments

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                        AGENT MEMORY                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   REST API (8000)                         │  │
│  │                                                           │  │
│  │  • Graph Operations (entity CRUD)                         │  │
│  │  • Memory Operations (store/recall)                       │  │
│  │  • Search Operations (semantic + intelligent)             │  │
│  │  • Knowledge Operations (extraction)                      │  │
│  │  • Dataset Management                                     │  │
│  │  • Cognitive Configuration                                │  │
│  │                                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐  ┌───────────────────┐  ┌───────────────┐
│    Neo4j      │  │   PostgreSQL      │  │  LLM Provider │
│ (Knowledge    │  │   (pgvector)      │  │  (Embeddings  │
│    Graph)     │  │   (Embeddings)    │  │   + LLM)      │
└───────────────┘  └───────────────────┘  └───────────────┘
```

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- kubectl configured to communicate with your cluster
- Neo4j database (optional, for knowledge graph features)
- PostgreSQL with pgvector extension (for embeddings)

## Installation

### Development Environment

```bash
helm install agent-memory ./agent-memory \
  --values ./agent-memory/values.yaml \
  --namespace kubiya \
  --create-namespace
```

### Production Environment

```bash
helm upgrade --install agent-memory ./agent-memory \
  --values ./agent-memory/values.yaml \
  --values ./agent-memory/values-prod.yaml \
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
| `name` | Service name | `agent-memory` |
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Image repository | `ghcr.io/kubiyabot/context-graph-api` |
| `image.tag` | Image tag (defaults to appVersion) | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets | `[]` |
| `command` | Override container command | `[]` |
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |
| `podAnnotations` | Pod annotations | Prometheus scraping |
| `podSecurityContext` | Pod security context | `{}` |
| `securityContext` | Container security context | `{}` |
| `service.enabled` | Enable service | `true` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `8000` |
| `service.annotations` | Service annotations | `{}` |
| `resources.limits.cpu` | CPU limit | `2000m` |
| `resources.limits.memory` | Memory limit | `2Gi` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.requests.memory` | Memory request | `512Mi` |
| `livenessProbe.*` | Liveness probe config | See values.yaml |
| `readinessProbe.*` | Readiness probe config | See values.yaml |
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.host` | Ingress host | `agent-memory.example.com` |
| `ingress.tlsSecretName` | TLS secret name | `""` |
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | HPA min replicas | `2` |
| `autoscaling.maxReplicas` | HPA max replicas | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU | `70` |
| `autoscaling.targetMemoryUtilizationPercentage` | Target memory | `80` |
| `pdb.enabled` | Enable PDB | `true` |
| `pdb.maxUnavailable` | PDB max unavailable | `1` |
| `env` | Environment variables (list format) | See below |
| `envFrom` | Secret/ConfigMap references | See default |
| `configMap.enabled` | Enable ConfigMap | `true` |
| `configMap.data` | Additional ConfigMap data | `{}` |
| `secret.enabled` | Enable Secret creation | `false` |
| `secret.data` | Secret data | `{}` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Pod tolerations | `[]` |
| `affinity` | Pod affinity (anti-affinity by default) | See values.yaml |

### Environment Variables

Environment variables are sourced from three places:

**1. Hardcoded in templates (static, cannot be changed):**

| Variable | Value | Reason |
|----------|-------|--------|
| `PORT` | Derived from `service.targetPort` | Matches service config |
| `PYTHONUNBUFFERED` | `"1"` | Python framework requirement |
| `DATA_ROOT_DIRECTORY` | `/tmp/cognee/data` | Cognee framework convention |
| `SYSTEM_ROOT_DIRECTORY` | `/tmp/cognee/system` | Cognee framework convention |
| `CACHE_ROOT_DIRECTORY` | `/tmp/cognee/cache` | Cognee framework convention |
| `API_TITLE` | `"Agent Memory API"` | Static metadata (ConfigMap) |
| `API_DESCRIPTION` | Service description | Static metadata (ConfigMap) |
| `API_VERSION` | Chart appVersion | Static metadata (ConfigMap) |
| `CONTROL_PLANE_API_BASE` | Auto-configured | Smart default from release name |

**2. Configurable via `env` in values.yaml (list format):**

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | Deployment environment | `production` (from global) |
| `LOG_LEVEL` | Log level (DEBUG, INFO, WARNING, ERROR) | `INFO` (from global) |

**3. Required via secrets (envFrom):**

See [Environment Variables Reference](#environment-variables-reference) section below.

## Dependencies

The Agent Memory service requires the following external services:

| Service | Purpose | Required |
|---------|---------|----------|
| PostgreSQL (pgvector) | Vector embeddings storage | Yes |
| Neo4j | Knowledge graph storage | No (optional) |
| LLM Provider | Embeddings and LLM calls via LiteLLM | Yes |
| Agent Orchestrator API | Authentication and org context | No |

## Secrets Management

### Creating Secrets for Production

The production configuration expects secrets to be created separately. Create a secret with the following command:

```bash
kubectl create secret generic agent-memory-secrets \
  --namespace kubiya \
  --from-literal=NEO4J_URI="bolt://neo4j:7687" \
  --from-literal=NEO4J_USERNAME="neo4j" \
  --from-literal=NEO4J_PASSWORD="your_password" \
  --from-literal=NEO4J_DATABASE="neo4j" \
  --from-literal=SQL_DATABASE_URL="postgresql://user:password@host:5432/memories" \
  --from-literal=DB_PROVIDER="postgres" \
  --from-literal=DB_HOST="postgresql" \
  --from-literal=DB_PORT="5432" \
  --from-literal=DB_NAME="memories" \
  --from-literal=DB_USERNAME="postgres" \
  --from-literal=DB_PASSWORD="your_password" \
  --from-literal=KUBIYA_API_BASE="https://api.kubiya.ai" \
  --from-literal=CONTROL_PLANE_API_BASE="http://agent-orchestrator-api:80" \
  --from-literal=LLM_PROVIDER="custom" \
  --from-literal=LLM_MODEL="openai/gpt-4" \
  --from-literal=LLM_API_KEY="your_litellm_api_key" \
  --from-literal=LLM_ENDPOINT="http://litellm:4000/v1" \
  --from-literal=EMBEDDING_PROVIDER="custom" \
  --from-literal=EMBEDDING_MODEL="openai/text-embedding-3-large" \
  --from-literal=EMBEDDING_API_KEY="your_litellm_api_key" \
  --from-literal=EMBEDDING_ENDPOINT="http://litellm:4000/v1" \
  --from-literal=EMBEDDING_DIMENSIONS="3072"
```

### Environment Variables Reference

| Variable | Description | Required |
|----------|-------------|----------|
| `NEO4J_URI` | Neo4j connection URI | No |
| `NEO4J_USERNAME` | Neo4j username | No |
| `NEO4J_PASSWORD` | Neo4j password | No |
| `SQL_DATABASE_URL` | PostgreSQL connection string | Yes |
| `DB_PROVIDER` | Database provider (postgres) | Yes |
| `DB_HOST` | PostgreSQL host | Yes |
| `DB_PORT` | PostgreSQL port | Yes |
| `DB_NAME` | Database name (memories) | Yes |
| `DB_USERNAME` | PostgreSQL username | Yes |
| `DB_PASSWORD` | PostgreSQL password | Yes |
| `LLM_PROVIDER` | LLM provider type | Yes |
| `LLM_MODEL` | LLM model name | Yes |
| `LLM_API_KEY` | LLM API key | Yes |
| `LLM_ENDPOINT` | LLM API endpoint | Yes |
| `EMBEDDING_PROVIDER` | Embedding provider type | Yes |
| `EMBEDDING_MODEL` | Embedding model name | Yes |
| `EMBEDDING_API_KEY` | Embedding API key | Yes |
| `EMBEDDING_ENDPOINT` | Embedding API endpoint | Yes |
| `EMBEDDING_DIMENSIONS` | Embedding vector dimensions | Yes |
| `KUBIYA_API_BASE` | Kubiya API base URL | No |
| `CONTROL_PLANE_API_BASE` | Agent Orchestrator API URL | Auto |

### Cognee Cloud (Alternative to Self-Hosted)

Instead of running Neo4j + pgvector yourself, you can use Cognee Cloud:

| Variable | Description | Required |
|----------|-------------|----------|
| `COGNEE_CLOUD_API_KEY` | Cognee Cloud API key | No |
| `COGNEE_CLOUD_API_BASE` | Cognee Cloud API URL | No |

With Cognee Cloud, you only need PostgreSQL for metadata - no Neo4j or vector database setup required.

### Intelligent Search Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `LITELLM_DEFAULT_MODEL` | Default model for intelligent search | `kubiya/claude-sonnet-4` |
| `SEARCH_STRATEGY` | Agent runtime: `claude_sdk` or `agno` | `claude_sdk` |
| `SEARCH_SESSION_TTL_MINUTES` | Multi-turn session TTL | `30` |
| `COGNEE_LOG_LEVEL` | Cognee internal log level | `WARNING` |

## Health Checks

The chart includes liveness and readiness probes:

- **Liveness Probe**: `/health` endpoint
  - Initial delay: 30 seconds
  - Period: 10 seconds
  - Timeout: 5 seconds
  - Failure threshold: 3

- **Readiness Probe**: `/health` endpoint
  - Initial delay: 10 seconds
  - Period: 5 seconds
  - Timeout: 3 seconds
  - Failure threshold: 3

## Monitoring

The chart includes Prometheus annotations for metrics scraping:

```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "8000"
prometheus.io/path: "/metrics"
```

## Upgrading

To upgrade an existing release:

```bash
helm upgrade agent-memory ./agent-memory \
  --values ./agent-memory/values.yaml \
  --values ./agent-memory/values-prod.yaml \
  --namespace kubiya
```

## Uninstalling

To uninstall/delete the deployment:

```bash
helm uninstall agent-memory --namespace kubiya
```

## Values Files

- `values.yaml`: Default values for development and base configuration
- `values-prod.yaml`: Production-specific overrides and configuration

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
replicaCount: 3
pdb:
  enabled: true
  maxUnavailable: 1  # Safe: always allows draining 1 pod
  # minAvailable: 2  # Alternative, but riskier with HPA

autoscaling:
  enabled: true
  minReplicas: 2  # Must be > maxUnavailable to avoid deadlock
  maxReplicas: 10
```

### Pod Anti-Affinity

Enabled by default to spread replicas across nodes. One node failure won't take down all replicas.

## Support

For issues and questions, please refer to the main repository documentation or open an issue.
