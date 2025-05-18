# Dagger Helm Chart

This is clone (~fork) of vendor (dagger helm chart)[https://github.com/dagger/dagger/tree/main/helm] version 0.15.0.

Motivation behind cloning was to add support for kubiya-runner:

- Original versions not in active development & not really production grade.
- Some key features missing needed by `kubiya-runner` which uses `dagger` as dependency chart.

# Documentation

## Security Context Configuration

The Dagger engine runs with secure defaults. The chart provides configurable security context settings for both the pod and container:

### Pod Security Context

```yaml
engine:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    fsGroupChangePolicy: "OnRootMismatch"
```

### Container Security Context

```yaml
engine:
  containerSecurityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
    readOnlyRootFilesystem: true
```

Note: If your workload requires privileged access or specific capabilities, you can override these settings in your values file with less restrictive options.

#### Legacy (Less Secure) Settings

For workloads that require privileged access, the following settings can be used:

```yaml
engine:
  securityContext:
    runAsUser: 0
    runAsGroup: 1001
    fsGroup: 1001
    
  containerSecurityContext:
    privileged: true
    capabilities:
      add:
        - ALL
```
