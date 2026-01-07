# Control Plane Temporal Helm Chart

A Helm chart for deploying the Kubiya Control Plane Temporal Service. This chart supports deploying the application in two modes: **API** and **Worker**.

## Architecture

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
helm upgrade --install control-plane-temporal oci://ghcr.io/<OWNER>/charts/control-plane-temporal \
  --version 0.1.0 \
  --namespace default \
  --create-namespace
```

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter             | Description                        | Default                     |
| --------------------- | ---------------------------------- | --------------------------- |
| `image.repository`    | Image repository                   | `control-plane-temporal`    |
| `image.tag`           | Image tag (defaults to appVersion) | `""`                        |
| `env.ENVIRONMENT`     | Deployment environment             | `production`                |
| `env.TEMPORAL_HOST`   | Temporal Frontend Address          | `temporal-frontend...:7233` |
| `api.enabled`         | Enable API Deployment              | `true`                      |
| `api.replicaCount`    | Number of API replicas             | `1`                         |
| `worker.enabled`      | Enable Worker Deployment           | `true`                      |
| `worker.replicaCount` | Number of Worker replicas          | `1`                         |

### Mode Selection
You can enable or disable components using values:

```yaml
# Only deploy Worker
api:
  enabled: false
worker:
  enabled: true
```

### Secrets
Sensitive environment variables (API Keys) should be managed via Secrets. You can inject them via `envSecrets` or external Secret management.

```yaml
envSecrets:
  KUBIYA_API_KEY: "your-key"
  LITELLM_API_KEY: "your-key"
```
