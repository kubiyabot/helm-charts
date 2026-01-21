# Policy Enforcer (OPA Watchdog)

Optional policy enforcement service for Kubiya. This chart deploys the OPA Watchdog
service used by the Agent Orchestrator for pre-execution policy checks.

## Usage

Enable it in `kubiya-stack`:

```yaml
policy-enforcer:
  enabled: true
```

When enabled, the Agent Orchestrator defaults `ENFORCER_SERVICE_URL` to the
in-cluster service (`http://<release>-policy-enforcer:5001`). Override as needed
via `agent-orchestrator.env.ENFORCER_SERVICE_URL`.

## Configuration

| Key                | Description                             | Default                         |
| ------------------ | --------------------------------------- | ------------------------------- |
| `enabled`          | Deploy the policy enforcer              | `false`                         |
| `replicaCount`     | Number of replicas                      | `1`                             |
| `image.repository` | Image repository                        | `ghcr.io/kubiyabot/opawatchdog` |
| `image.tag`        | Image tag                               | `v0.0.7`                        |
| `service.port`     | Service port                            | `5001`                          |
| `env`              | Environment variables for the container | `{}`                            |
| `livenessProbe.*`  | Liveness probe timing                   | See `values.yaml`               |
| `readinessProbe.*` | Readiness probe timing                  | See `values.yaml`               |

## Secrets

This chart does not require any secrets by default. If your deployment
requires credentials, supply them via Kubernetes secrets and reference them
using `env` in a custom overlay.
