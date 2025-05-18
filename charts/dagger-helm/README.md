# Dagger Helm Chart

This is clone (~fork) of vendor (dagger helm chart)[https://github.com/dagger/dagger/tree/main/helm] version 0.15.0.

Motivation behind cloning was to add support for kubiya-runner:

- Original versions not in active development & not really production grade.
- Some key features missing needed by `kubiya-runner` which uses `dagger` as dependency chart.

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

The Dagger engine is configured with a balanced security approach. Due to the nature of container runtimes, some privileged access is required at the container level, but we maintain enhanced pod-level security where possible:

### Pod Security Context (More Secure)

```yaml
engine:
  securityContext:
    runAsNonRoot: false # Cannot be true for Dagger due to cgroup management
    runAsUser: 0        # Needed for cgroup access
    fsGroup: 1001
    fsGroupChangePolicy: "OnRootMismatch"
```

### Container Security Context (Required Privileges)

```yaml
engine:
  containerSecurityContext:
    privileged: true # Required for container runtime
    capabilities:
      add:
        - ALL # Required for container runtime
    readOnlyRootFilesystem: false # Cannot be enabled - container needs to write to system directories
```

> **Why Privileged Mode is Required**: Dagger engine needs to access and modify cgroup configurations and other system resources to support nested containerization. According to the [Docker-in-Docker implementation](https://github.com/moby/moby/blob/38805f20f9bcc5e87869d6c79d432b166e1c88b4/hack/dind), the container must be able to write to `/sys/fs/cgroup` and other system locations, which requires privileged mode.

> **Security Balancing**: We make a concerted effort to follow security best practices, but container runtimes like Dagger inherently require elevated privileges to function properly.
