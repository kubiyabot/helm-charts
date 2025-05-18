# Dagger Helm Chart

This is clone (~fork) of vendor (dagger helm chart)[https://github.com/dagger/dagger/tree/main/helm] version 0.15.0.

Motivation behind cloning was to add support for kubiya-runner:

- Original versions not in active development & not really production grade.
- Some key features missing needed by `kubiya-runner` which uses `dagger` as dependency chart.

# Documentation

## Security Context Configuration

By default, the Dagger engine runs with privileged access. The chart allows customizing security context settings for both the pod and container:

### Pod Security Context

```yaml
engine:
  securityContext:
    runAsUser: 0
    runAsGroup: 1001
    fsGroup: 1001
    fsGroupChangePolicy: "OnRootMismatch"
    # For enhanced security (requires compatible workload):
    # runAsNonRoot: true
    # runAsUser: 1000
    # fsGroup: 2000
```

### Container Security Context

```yaml
engine:
  containerSecurityContext:
    privileged: true
    capabilities:
      add:
        - ALL
    # For enhanced security (requires compatible workload):
    # allowPrivilegeEscalation: false
    # capabilities:
    #   drop:
    #     - ALL
    # readOnlyRootFilesystem: true
```

Note: Enabling the enhanced security options may require modifications to your workload to ensure compatibility.
