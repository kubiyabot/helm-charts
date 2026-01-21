# Kubiya Stack

The official Umbrella Helm Chart for deploying the complete Kubiya AI Agent infrastructure.

## Overview

Kubiya is a **multi-tenant AI agent orchestration platform** that enables you to create, configure, schedule, and execute AI agents at scale. This stack deploys all the core microservices and infrastructure needed to run the platform.

## Architecture

### Component Relationships
```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTROL PLANE CORE                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   REST API      │  │   WebSocket     │  │   Worker        │  │
│  │   (FastAPI)     │  │   Streaming     │  │   (Temporal)    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  PostgreSQL     │  │     Redis       │  │    Temporal     │
│  (RLS)          │  │  (Cache/PubSub) │  │   (Workflows)   │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### High-Level System Architecture

```
   ┌──────────────────────────────────────────────────────────────────────────┐
   │                            CONTROL PLANE                                 │
   │  ┌─────────────────────────┐    ┌─────────────────────────────────────┐  │
   │  │      API Server         │    │           Worker                    │  │
   │  │  ────────────────────   │    │   ─────────────────────────────     │  │
   │  │  - Agent CRUD           │    │   - Temporal Workflow Execution     │  │
   │  │  - Team Management      │    │   - Agent/Team Execution            │  │
   │  │  - Job Scheduling       │    │   - Background Tasks                │  │
   │  │  - Workflow Orchestration│   │   - Queue Processing                │  │
   │  │  - Real-time Streaming  │    │   - Heartbeat Registration          │  │
   │  │  - Integration Mgmt     │    │                                     │  │
   │  │  - Policy Enforcement   │    │                                     │  │
   │  └─────────────────────────┘    └─────────────────────────────────────┘  │
   └──────────────────────────────────────────────────────────────────────────┘
                                      │
           ┌──────────────────────────┼──────────────────────────┐
           │                          │                          │
           ▼                          ▼                          ▼
  ┌─────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
  │ TEMPORAL WORKER │    │   CONTEXT GRAPH     │    │     LITELLM         │
  │  ─────────────  │    │  ───────────────    │    │  ─────────────      │
  │  - REST API for │    │  - Knowledge Graph  │    │  - AI Gateway       │
  │    workflow mgmt│    │  - Semantic Search  │    │  - LLM Proxy        │
  │  - Temporal     │    │  - Agent Memory     │    │  - Multi-provider   │
  │    Worker       │    │  - Dataset Mgmt     │    │    (OpenAI/Claude)  │
  │  - Long-running │    │  - RBAC             │    │                     │
  │    tasks        │    │                     │    │                     │
  └─────────────────┘    └─────────────────────┘    └─────────────────────┘
                                        │
          ┌─────────────────────────────┼─────────────────────────────┐
          │                             │                             │
          ▼                             ▼                             ▼
 ┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐
 │     PostgreSQL      │   │       Redis         │   │       Neo4j         │
 │     + pgvector      │   │                     │   │     + APOC          │
 │  ─────────────────  │   │  ─────────────────  │   │  ─────────────────  │
 │  - Agent state      │   │  - Cache            │   │  - Knowledge graphs │
 │  - Executions       │   │  - Pub/Sub events   │   │  - Entity relations │
 │  - Jobs/Workflows   │   │  - Embeddings       │   │  - Graph queries    │
 │  - Embeddings       │   │  - Session storage  │   │                     │
 └─────────────────────┘   └─────────────────────┘   └─────────────────────┘
```

### Component Interaction Diagram

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#8b5cf6', 'primaryTextColor': '#fff', 'primaryBorderColor': '#7c3aed', 'lineColor': '#6b7280', 'secondaryColor': '#c084fc', 'tertiaryColor': '#f3e8ff'}}}%%
graph TB
    subgraph External["External Services"]
        USER[Users/API Clients]
        TC[Temporal Cloud]
        LLM_EXT[LLM Providers<br/>OpenAI/Claude/etc]
    end

    subgraph Stack["Kubiya Stack"]
        subgraph ControlPlane["Agent Orchestrator"]
            CP_API[Agent Orchestrator API<br/>Port: 7777]
            CP_WORKER[Agent Orchestrator Worker]
        end

        subgraph TemporalWorker["Background Jobs"]
            TW_API[Background Jobs API<br/>Port: 8000]
            TW_WORKER[Background Jobs]
        end

        subgraph ContextGraph["Agent Memory"]
            CG_API[Agent Memory API<br/>Port: 8000]
        end

        LITELLM[LiteLLM Proxy<br/>Port: 4000]
    end

    subgraph Infra["Infrastructure"]
        PG[(PostgreSQL<br/>+ pgvector)]
        REDIS[(Redis)]
        NEO4J[(Neo4j)]
    end

    USER -->|REST API| CP_API
    USER -->|WebSocket| CP_API

    CP_API -->|State| PG
    CP_API -->|Cache/Events| REDIS
    CP_API -.->|Memory/Search| CG_API
    CP_API -.->|LLM Calls| LITELLM
    CP_WORKER -->|Poll Tasks| TC
    CP_WORKER -->|State| CP_API

    TW_API -->|Workflow State| TC
    TW_WORKER -->|Poll Tasks| TC
    TW_WORKER -->|Fetch Data| CP_API

    CG_API -->|Graph Data| NEO4J
    CG_API -->|Embeddings| PG
    CG_API -.->|LLM/Embed| LITELLM

    LITELLM -->|Forward| LLM_EXT

    style USER fill:#3b82f6,stroke:#2563eb,color:#fff
    style TC fill:#f59e0b,stroke:#d97706,color:#fff
    style LLM_EXT fill:#f59e0b,stroke:#d97706,color:#fff
    style CP_API fill:#8b5cf6,stroke:#7c3aed,color:#fff
    style CP_WORKER fill:#06b6d4,stroke:#0891b2,color:#fff
    style TW_API fill:#8b5cf6,stroke:#7c3aed,color:#fff
    style TW_WORKER fill:#06b6d4,stroke:#0891b2,color:#fff
    style CG_API fill:#8b5cf6,stroke:#7c3aed,color:#fff
    style LITELLM fill:#c084fc,stroke:#a855f7,color:#fff
    style PG fill:#10b981,stroke:#059669,color:#fff
    style REDIS fill:#10b981,stroke:#059669,color:#fff
    style NEO4J fill:#10b981,stroke:#059669,color:#fff
```

### Data Flow: Agent Execution

```mermaid
sequenceDiagram
    participant User
    participant CP as Agent Orchestrator API
    participant Worker as CP Worker
    participant TC as Temporal Cloud
    participant CG as Agent Memory
    participant Redis
    participant PG as PostgreSQL
    participant LLM as LiteLLM

    Note over User,LLM: Agent Execution Flow

    User->>CP: POST /api/v1/agents/{id}/execute
    CP->>PG: Load agent config, skills, integrations
    CP->>TC: Start AgentExecutionWorkflow
    CP->>Redis: Publish execution_started event
    CP-->>User: Return execution_id + stream URL

    TC->>Worker: Dispatch workflow task
    Worker->>CP: Get agent context
    Worker->>CG: Recall relevant memories
    CG-->>Worker: Return context
    Worker->>LLM: Generate response
    LLM-->>Worker: LLM response
    Worker->>Redis: Stream execution events
    Worker->>PG: Update execution state

    User->>CP: GET /api/v1/executions/{id}/stream
    CP->>Redis: Subscribe to events
    Redis-->>CP: Stream events
    CP-->>User: SSE stream

    Worker->>CP: Complete workflow
    Worker->>CG: Store new memories
    CP->>PG: Finalize execution
    CP->>Redis: Publish execution_completed
```

## Components

| Component | Chart | Description | Dependencies |
|-----------|-------|-------------|--------------|
| **Agent Orchestrator** | `agent-orchestrator` | Multi-tenant API and worker for AI agent orchestration. Handles agent CRUD, team management, job scheduling, workflow orchestration, real-time event streaming, and policy enforcement. | PostgreSQL, Redis |
| **Background Jobs** | `background-jobs` | REST API for workflow management + Temporal worker for long-running background tasks. Executes workflows that interact with Agent Orchestrator. | Temporal Cloud |
| **Agent Memory** | `agent-memory` | Cognitive memory and knowledge graph service. Provides semantic search, memory storage, knowledge extraction, and dataset management for agents. | Neo4j, PostgreSQL |
| **Policy Enforcer (optional)** | `policy-enforcer` | OPA Watchdog service for pre-execution policy evaluation and governance. | None |
| **LiteLLM** | `litellm` | AI Gateway/Proxy for unified LLM access. Routes requests to OpenAI, Claude, and other providers. | None |

### Agent Orchestrator Capabilities

The Agent Orchestrator is the core of the platform with 30+ API routers:

- **Agent Management** - Create, configure, and manage AI agents
- **Team Orchestration** - Coordinate multiple agents for complex tasks
- **Job Scheduling** - Cron-based and webhook-triggered agent execution
- **Workflow Engine** - Multi-step automation pipelines
- **Skills & Tools** - Define agent capabilities and integrations
- **Real-time Streaming** - WebSocket, Redis Pub/Sub, NATS event delivery
- **Policy Enforcement** - OPA-based tool usage policies
- **Analytics** - Execution metrics and performance monitoring

### Agent Memory Capabilities

The Agent Memory provides cognitive capabilities:

- **Knowledge Graph** - Neo4j-based entity and relationship storage
- **Semantic Search** - AI-powered similarity search across memories
- **Memory Storage** - Store and recall contextual information
- **Dataset Management** - Organize and process document collections
- **Knowledge Extraction** - Extract entities from unstructured data
- **Multi-tenant RBAC** - Organization-scoped access control

## Infrastructure

| Component | Chart | Purpose |
|-----------|-------|---------|
| **PostgreSQL** | `bitnami/postgresql` | Primary database with pgvector extension for embeddings. Uses Row-Level Security (RLS) for multi-tenant isolation. |
| **Redis** | `bitnami/redis` | Cache, pub/sub for real-time events, session storage. **Recommended even for small deployments** - enables real-time streaming with 70% latency improvement over HTTP polling. |
| **Neo4j** | `neo4j/neo4j` | Knowledge graph database (required only if agent-memory enabled) |

## Quick Start

### 1. Install via OCI (Recommended)

```bash
# Add required repos for dependencies
helm repo add neo4j https://helm.neo4j.com/neo4j

# Install full stack
helm install kubiya oci://ghcr.io/kubiyabot/charts/kubiya-stack \
  --version 0.1.0 \
  --namespace kubiya \
  --create-namespace
```

### 2. Minimal Installation (Agent Orchestrator Only)

```bash
helm install kubiya oci://ghcr.io/kubiyabot/charts/kubiya-stack \
  --version 0.1.0 \
  --namespace kubiya \
  --set background-jobs.enabled=false \
  --set agent-memory.enabled=false \
  --set litellm.enabled=false
```

### 3. Production Setup (External Databases)

For production, use managed databases (RDS, ElastiCache, AuraDB):

```bash
helm install kubiya oci://ghcr.io/kubiyabot/charts/kubiya-stack \
  --version 0.1.0 \
  --namespace kubiya \
  --set postgresql.enabled=false \
  --set redis.enabled=false \
  --set neo4j.enabled=false \
  --set agent-memory.enabled=true
```

## Configuration

### Global Configuration

This chart supports global configuration that is shared across all charts in the stack:

```yaml
global:
  environment: "production"
  logLevel: "INFO"
  existingSecret: "my-shared-secrets"  # Optional: secret injected into all components
  security:
    allowInsecureImages: true  # Required for pgvector image
  policyEnforcer:
    enabled: false  # Enables ENFORCER_SERVICE_URL defaults for agent-orchestrator
```

### Component Toggle

```yaml
# Core (required)
agent-orchestrator:
  enabled: true
  api:
    enabled: true
    replicaCount: 2
  worker:
    enabled: true
    replicaCount: 2

# Background Jobs (recommended)
background-jobs:
  enabled: true
  api:
    enabled: true
  worker:
    enabled: true

# Memory/Knowledge (optional)
agent-memory:
  enabled: false  # Enable if you need agent memory

# Policy Enforcement (optional)
policy-enforcer:
  enabled: false

# AI Gateway (optional)
litellm:
  enabled: false  # Enable for multi-LLM support
```

### Policy Enforcement Integration

When `policy-enforcer.enabled` and `global.policyEnforcer.enabled` are true, the
Agent Orchestrator automatically defaults `ENFORCER_SERVICE_URL` to the in-cluster service:

```yaml
agent-orchestrator:
  env:
    ENFORCER_SERVICE_URL: "http://kubiya-policy-enforcer:5001"  # override if needed
```

### Infrastructure

```yaml
# PostgreSQL with pgvector
postgresql:
  enabled: true
  image:
    repository: ankane/pgvector
    tag: v0.5.1
  global:
    postgresql:
      auth:
        database: agent_control_plane
        password: "change-me-in-production"

# Redis
redis:
  enabled: true
  architecture: standalone
  auth:
    enabled: false

# Neo4j (only if agent-memory enabled)
neo4j:
  enabled: false
  neo4j:
    edition: community
    password: "change-me-in-production"
```

## Production Configuration

### Worker Scaling

For production workloads, increase worker replicas to handle concurrent agent executions:

```yaml
agent-orchestrator:
  worker:
    replicaCount: 4  # Recommended for production
    resources:
      requests:
        cpu: 250m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 2Gi
```

### WebSocket & Real-time Streaming

Agent Orchestrator uses WebSocket for real-time execution streaming. Ensure proper configuration:

```yaml
agent-orchestrator:
  api:
    service:
      sessionAffinity: ClientIP  # Required for WebSocket sticky sessions
      sessionAffinityConfig:
        clientIP:
          timeoutSeconds: 10800  # 3 hours
    ingress:
      annotations:
        nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
        nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
```

These settings are **already configured by default** in the agent-orchestrator chart.

### Jobs and Temporal Configuration

**Important**: Job scheduling (cron jobs, webhook triggers) requires Temporal configuration. Without properly configured Temporal:
- Jobs can be created via API/UI
- Job schedules will be stored in the database
- **But cron jobs will NOT execute** - they won't be registered with Temporal

Ensure these secrets are set:
- `TEMPORAL_HOST` - Temporal server address (required)
- `TEMPORAL_NAMESPACE` - Temporal namespace (required)
- `TEMPORAL_API_KEY` - For Temporal Cloud authentication (if using cloud)

### LiteLLM Integration

Agent Orchestrator integrates with LiteLLM for multi-provider LLM access:

```yaml
# Environment variables for LiteLLM
LITELLM_API_BASE: "http://litellm:4000"  # Internal service or external URL
LITELLM_API_KEY: "your-key"               # If authentication required
LITELLM_DEFAULT_MODEL: "kubiya/claude-sonnet-4"
LITELLM_MODELS_CACHE_TTL: "300"           # 5-minute cache (default)
```

**Features**:
- Dynamic model fetching from LiteLLM server
- 5-minute cache with graceful degradation
- Model validation before agent creation

### Agent Memory Integration

Agent Orchestrator proxies requests to Agent Memory for memory features:

```yaml
# Environment variables
CONTEXT_GRAPH_API_BASE: "http://agent-memory:8000"  # Internal service
CONTEXT_GRAPH_API_TIMEOUT: "30"                      # Request timeout
```

**Proxy Routes**: Agent Orchestrator exposes `/api/v1/agent-memory/*` endpoints that forward to Agent Memory service. This enables:
- Built-in "Contextual Awareness" skill
- Memory recall during agent execution
- Knowledge graph queries

### Observability (OpenTelemetry)

Agent Orchestrator supports distributed tracing via OpenTelemetry:

```yaml
agent-orchestrator:
  env:
    OTEL_ENABLED: "true"
    OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector:4317"
    OTEL_SERVICE_NAME: "agent-orchestrator"
    OTEL_TRACES_SAMPLER: "parentbased_traceidratio"
    OTEL_TRACES_SAMPLER_ARG: "0.1"  # 10% sampling in production
```

See [agent-orchestrator README](./charts/agent-orchestrator/README.md#observability-opentelemetry) for full configuration options.

### High Availability

#### Pod Disruption Budgets

All charts include PDBs (enabled by default, created when `replicaCount > 1`) using `maxUnavailable: 1`.

**WARNING: Common PDB Pitfalls**

| Misconfiguration | Problem |
|------------------|---------|
| `minAvailable >= replicaCount` | Pods become undrainable. Node upgrades will hang indefinitely. |
| `replicaCount: 1` with PDB | PDB is useless (math requires 2+ replicas). Templates auto-disable in this case. |
| PDB + HPA + Cluster Autoscaler | Can deadlock if `minAvailable` equals HPA `minReplicas`. Always use `maxUnavailable` instead. |

**Safe configuration:**

```yaml
agent-orchestrator:
  api:
    replicaCount: 3
    pdb:
      enabled: true
      maxUnavailable: 1  # Safe: always allows draining 1 pod
    autoscaling:
      enabled: true
      minReplicas: 2     # Must be > maxUnavailable to avoid deadlock
  worker:
    replicaCount: 4
    pdb:
      enabled: true
      maxUnavailable: 1
```

#### Pod Anti-Affinity

All charts include pod anti-affinity by default to spread replicas across nodes. One node failure won't take down all replicas.

## Secrets Management

This chart does **not** include vendor-specific secret management. Create secrets externally using your preferred solution (External Secrets Operator, Vault, 1Password, etc.).

### Required Secrets

#### Agent Orchestrator

```bash
kubectl create secret generic agent-orchestrator-secrets \
  --namespace kubiya \
  --from-literal=DATABASE_URL="postgresql://user:pass@host:5432/db" \
  --from-literal=REDIS_URL="redis://redis:6379/0" \
  --from-literal=SECRET_KEY="$(openssl rand -hex 32)" \
  --from-literal=JWT_SECRET="$(openssl rand -hex 32)" \
  --from-literal=TEMPORAL_HOST="your-namespace.tmprl.cloud:7233" \
  --from-literal=TEMPORAL_NAMESPACE="your-namespace" \
  --from-literal=TEMPORAL_API_KEY="your-temporal-api-key"
```

#### Background Jobs (if enabled)

```bash
kubectl create secret generic background-jobs-secrets \
  --namespace kubiya \
  --from-literal=TEMPORAL_HOST="your-namespace.tmprl.cloud:7233" \
  --from-literal=TEMPORAL_API_KEY="your-temporal-api-key" \
  --from-literal=KUBIYA_API_KEY="your-internal-api-key"
```

#### Agent Memory (if enabled)

```bash
kubectl create secret generic agent-memory-secrets \
  --namespace kubiya \
  --from-literal=NEO4J_URI="bolt://neo4j:7687" \
  --from-literal=NEO4J_PASSWORD="your-neo4j-password" \
  --from-literal=SQL_DATABASE_URL="postgresql://user:pass@host:5432/db" \
  --from-literal=LLM_API_KEY="your-litellm-api-key"
```

### Reference Secrets in Values

```yaml
agent-orchestrator:
  envFrom:
    - secretRef:
        name: agent-orchestrator-secrets

background-jobs:
  envFrom:
    - secretRef:
        name: background-jobs-secrets

agent-memory:
  envFrom:
    - secretRef:
        name: agent-memory-secrets
```

## Ingress Configuration

### Agent Orchestrator API

```yaml
agent-orchestrator:
  api:
    ingress:
      enabled: true
      host: api.kubiya.example.com
      tlsSecretName: api-tls
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt-prod
```

### Background Jobs API

```yaml
background-jobs:
  api:
    ingress:
      enabled: true
      host: jobs.kubiya.example.com
      tlsSecretName: jobs-tls
```

### Agent Memory API

```yaml
agent-memory:
  ingress:
    enabled: true
    host: graph.kubiya.example.com
    tlsSecretName: graph-tls
```

## Monitoring

All components expose Prometheus metrics:

| Component | Port | Path |
|-----------|------|------|
| Agent Orchestrator API | 8000 | /metrics |
| Background Jobs API | 8000 | /metrics |
| Agent Memory API | 8000 | /metrics |

Pod annotations are pre-configured for Prometheus scraping.

## Health Checks

| Component | Liveness | Readiness |
|-----------|----------|-----------|
| Agent Orchestrator API | `/api/health` | `/api/health` |
| Background Jobs API | `/health` | `/ready` |
| Agent Memory API | `/health` | `/health` |

## OCI Artifacts

All charts are published as individual OCI artifacts:

| Chart | OCI URL |
|-------|---------|
| Umbrella Stack | `oci://ghcr.io/kubiyabot/charts/kubiya-stack` |
| Agent Orchestrator | `oci://ghcr.io/kubiyabot/charts/agent-orchestrator` |
| Background Jobs | `oci://ghcr.io/kubiyabot/charts/background-jobs` |
| Agent Memory | `oci://ghcr.io/kubiyabot/charts/agent-memory` |

## Upgrading

```bash
helm upgrade kubiya oci://ghcr.io/kubiyabot/charts/kubiya-stack \
  --version 0.2.0 \
  --namespace kubiya \
  --reuse-values
```

## Uninstalling

```bash
helm uninstall kubiya --namespace kubiya
```

**Warning**: This will not delete PVCs. To fully clean up:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=kubiya -n kubiya
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n kubiya -l app.kubernetes.io/instance=kubiya
```

### View Logs

```bash
# Agent Orchestrator API
kubectl logs -n kubiya -l app.kubernetes.io/component=api,app.kubernetes.io/name=agent-orchestrator

# Agent Orchestrator Worker
kubectl logs -n kubiya -l app.kubernetes.io/component=worker,app.kubernetes.io/name=agent-orchestrator
```

### Common Issues

| Issue | Solution |
|-------|----------|
| PostgreSQL connection refused | Ensure postgresql pod is running and DATABASE_URL is correct |
| Temporal connection failed | Verify TEMPORAL_HOST and TEMPORAL_API_KEY secrets |
| Neo4j auth failed | Check NEO4J_PASSWORD matches the neo4j chart configuration |
| WebSocket disconnects | Ensure ingress has proper timeout annotations (3600s) |
| Cron jobs not executing | Ensure TEMPORAL_HOST and TEMPORAL_NAMESPACE are configured |

## References

### Official Documentation

- [Kubiya Platform Architecture](https://docs.kubiya.ai/core-concepts/control-plane/architecture) - Detailed architecture documentation
- [Self-Hosting Guide](https://docs.kubiya.ai/cli/control-plane-self-hosting) - Deployment options and requirements
- [Background Jobs](https://docs.kubiya.ai/core-concepts/background-jobs) - Job scheduling and Temporal integration
- [Cognitive Memory](https://docs.kubiya.ai/core-concepts/cognitive-memory) - Agent Memory and memory features

### Source Repositories

- [kubiyabot/helm-charts](https://github.com/kubiyabot/helm-charts) - This repository
- [Temporal Cloud](https://temporal.io/cloud) - Workflow orchestration platform
