# Cache Registry Component

The Cache Registry is a Docker registry component that provides image caching functionality for the Kubiya Tool Manager. It stores and serves Docker images locally within the Kubernetes cluster to improve performance and reduce external dependencies.

## Overview

The Cache Registry component consists of four Kubernetes resources:

1. **PersistentVolume (PV)**: `docker-registry-pv` - Provides persistent storage for registry data
2. **PersistentVolumeClaim (PVC)**: `docker-registry-pvc` - Claims storage from the PV
3. **Deployment**: `cache-registry` - Runs the Docker registry container
4. **Service**: `cache-registry-svc` - Exposes the registry within the cluster

## Configuration

The cache registry is configured through the `cacheRegistry` section in your values.yaml:

```yaml
cacheRegistry:
  enabled: true  # Set to false to disable the cache registry
  pv:
    name: "docker-registry-pv"
    size: "20Gi"
    hostPath: "/var/lib/registry"
  pvc:
    name: "docker-registry-pvc"
    size: "20Gi"
  deployment:
    name: "cache-registry"
    replicas: 1
    resources:
      limits:
        cpu: "500m"
        memory: "512Mi"
      requests:
        cpu: "100m"
        memory: "128Mi"
  service:
    name: "cache-registry-svc"
    port: 443
    targetPort: 5000
```

## Storage Options

### HostPath (Default)
Uses local node storage. Suitable for development and single-node clusters:
```yaml
pv:
  hostPath: "/var/lib/registry"
```

### Dynamic Provisioning
Uses a StorageClass for dynamic volume provisioning:
```yaml
pv:
  storageClass: "fast-ssd"
pvc:
  storageClass: "fast-ssd"
```

### NFS
Uses Network File System for shared storage:
```yaml
pv:
  volumeSource:
    nfs:
      server: "nfs-server.example.com"
      path: "/path/to/registry"
```

## Security

The registry is configured with TLS encryption using certificates from the `registry-tls-secret` Kubernetes secret. This secret must be created separately and contain:

- `tls.crt`: TLS certificate
- `tls.key`: TLS private key

## Environment Variables

The cache registry is automatically configured to work with the Tool Manager through these environment variables:

- `KUBIYA_IMAGE_REGISTRY_ADDRESS`: Points to the cache registry service
- Registry certificates are mounted at `/etc/docker/certs.d/cache-registry-svc.kubiya`

## Health Checks

The deployment includes both liveness and readiness probes:
- **Endpoint**: `/v2/` (Docker Registry API v2)
- **Port**: 5000
- **Scheme**: HTTPS

## Resource Requirements

Default resource allocation:
- **CPU**: 100m request, 500m limit
- **Memory**: 128Mi request, 512Mi limit
- **Storage**: 20Gi (configurable)

Adjust these values based on your usage patterns and cluster capacity.

## Monitoring

The cache registry can be monitored through:
- Registry API endpoints (`/v2/`)
- Kubernetes deployment and pod metrics
- Storage usage monitoring

## Troubleshooting

### Common Issues

1. **Pod not starting**: Check if the TLS secret exists
2. **Storage issues**: Verify PV/PVC configuration and storage availability
3. **Network connectivity**: Ensure service discovery is working

### Logs
```bash
kubectl logs -n <namespace> deployment/cache-registry
```

### Registry health check
```bash
kubectl port-forward -n <namespace> svc/cache-registry-svc 443:443
curl -k https://localhost:443/v2/
```

## Disabling the Cache Registry

To disable the cache registry component, set:
```yaml
cacheRegistry:
  enabled: false
```

Note: This will prevent the creation of all cache registry resources but will not affect the existing Tool Manager functionality. 