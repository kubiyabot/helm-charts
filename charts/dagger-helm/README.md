# Dagger Helm Chart

This is clone (~fork) of vendor (dagger helm chart)[https://github.com/dagger/dagger/tree/main/helm] with enhanced security configurations and customizations for Kubiya Runner.

Enhancements include:
- Updated to use latest Dagger Engine (v0.18.8)
- Enhanced security context configuration with minimized privileges
- StatefulSet support with persistent volumes
- Custom configuration options for Kubiya Runner integration

# Documentation

## Deployment Options

The Dagger Helm chart supports two deployment options:

### DaemonSet (default)

The DaemonSet deployment ensures a single Dagger Engine instance runs on each Kubernetes node. This is useful when you want to provide container build capabilities on every node in your cluster.

### StatefulSet

The StatefulSet deployment allows for more robust workload management and is recommended for production environments. Key advantages:

- Use of persistent volumes for better data retention
- More predictable naming and addressing
- Better lifecycle management
- Configurable PVC retention policies

To use StatefulSet, set the following in your values:

```yaml
engine:
  kind: StatefulSet
  statefulSet:
    persistentVolumeClaim:
      enabled: true
      # Configure PVC settings as needed
```

## Security Context Configuration

Dagger Engine requires certain privileges to function since it's a container runtime. However, we've fine-tuned the security settings to minimize the attack surface:

### Pod Security Context

```yaml
engine:
  securityContext:
    runAsNonRoot: false # Cannot be true for Dagger due to cgroup management
    runAsUser: 0        # Needed for cgroup access
    fsGroup: 1001
    fsGroupChangePolicy: "OnRootMismatch"
```

### Container Security Context (Restricted Privileges)

```yaml
engine:
  containerSecurityContext:
    privileged: true  # Required for container runtime
    capabilities:
      # Only add essential capabilities instead of ALL
      add:
        - "NET_BIND_SERVICE"
        - "SYS_CHROOT"
        - "SETUID" 
        - "SETGID"
        - "DAC_OVERRIDE"
      # Drop unnecessary capabilities
      drop:
        - "NET_RAW"
        - "SYS_ADMIN"  # Try to drop this if possible
```

### Startup Flags for Improved Security

We've added specific startup flags to minimize privilege requirements:

```yaml
engine:
  args:
    - "--oci-max-parallelism" 
    - "4"
    - "--oci-worker-skip-check-cgroup=true"
```

The `--oci-worker-skip-check-cgroup` flag helps reduce the requirement for full cgroup access.

> **Why Some Privileges are Required**: Dagger engine needs to access system resources to support nested containerization. We've minimized privileges where possible, but container runtimes inherently require elevated access to function properly.

## Advanced Configuration

### Engine Configuration

The chart allows customizing the Dagger Engine configuration via TOML:

```yaml
engine:
  config: |
    insecure-entitlements = ["security.insecure"]
    [registry."ghcr.io"]
      http = true
    [log]
      format = "json"
      level = "info"
    [grpc]
      address = ["unix:///run/dagger/engine.sock", "tcp://0.0.0.0:8080"]
```

### Resource Management

Configure resource limits to prevent excessive resource consumption:

```yaml
engine:
  resources:
    limits:
      cpu: 2
      memory: 2Gi
    requests:
      cpu: 100m
      memory: 128Mi
```
