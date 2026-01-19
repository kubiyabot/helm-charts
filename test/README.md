# Helm Chart Testing

This directory contains test infrastructure for the Kubiya Helm charts.

## Structure

```
test/
├── docker-compose.yaml    # Local test services
├── init-db/               # Database initialization scripts
│   └── 01-init.sql        # PostgreSQL setup
├── mocks/                 # Mock services
│   ├── mock-litellm/      # Mock LiteLLM API
│   └── mock-control-plane/ # Mock Control Plane API
└── README.md              # This file
```

## Quick Start

### Start Test Services

```bash
# Start core services (PostgreSQL + Redis + Mocks)
docker-compose up -d

# Start full stack including Neo4j
docker-compose --profile full up -d
```

### Verify Services

```bash
# Check all services are healthy
docker-compose ps

# Test mock LiteLLM
curl http://localhost:4000/health

# Test mock Control Plane
curl http://localhost:7777/health

# Test PostgreSQL
psql postgresql://kubiya:kubiya@localhost:5432/agent_control_plane -c "SELECT 1"
```

### Run Helm Tests

```bash
# Lint all charts
for chart in charts/*; do
  helm lint "$chart"
done

# Template with test values
helm template test charts/kubiya-stack -f charts/kubiya-stack/ci/test-values.yaml

# Dry-run install
helm install --dry-run test charts/kubiya-stack -f charts/kubiya-stack/ci/test-values.yaml
```

## Test Values

Each chart has a `ci/test-values.yaml` file with minimal configuration for CI testing:

- Reduced resource limits
- Single replicas
- Disabled autoscaling
- Disabled ingress
- Test secrets references

## Mock Services

### Mock LiteLLM

Provides OpenAI-compatible endpoints:
- `POST /v1/chat/completions` - Chat completions with tool calling
- `POST /v1/embeddings` - Text embeddings
- `GET /health` - Health check

### Mock Control Plane

Provides Control Plane API endpoints:
- `GET /api/v1/auth/validate` - Token validation
- `GET /models` - List LLM models
- `GET /api/v1/creds/llm` - LLM credentials
- `GET /health` - Health check

## CI Integration

The test values are used by GitHub Actions workflows:

```yaml
- name: Lint with test values
  run: |
    helm lint charts/kubiya-stack -f charts/kubiya-stack/ci/test-values.yaml
```

## Cleanup

```bash
# Stop all services
docker-compose down

# Remove volumes
docker-compose down -v
```
