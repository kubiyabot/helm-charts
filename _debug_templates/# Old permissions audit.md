# Old permissions audit

## otel-collector-sa

Used in

- Deployment `otel-collector`

Total Permissions (via ClusterRole `otel-collector-cluster-role`):

```
apiGroups: [""]
resources: ["pods", "nodes", "deployments", "events", "namespaces", "endpoints", "services", "nodes/proxy", "nodes/metrics"]
verbs: ["get", "list", "watch"]

apiGroups: ["apps"]
resources: ["deployments", "statefulsets", "daemonsets", "replicasets"]
verbs: ["get", "list", "watch"]

nonResourceURLs: ["/metrics", "/metrics/cadvisor"]
verbs: ["get"]
```

## kubiya-service-account

Used in:

- Deployment `kubiya-operator`
- Deployment `tool-manager`

Total Permissions (via ClusterRole `kubiya-cluster-role`):

```
# Via ClusterRole kubiya-cluster-role:
apiGroups: [""]
resources: ["persistentvolumes"]
verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]

# Via Role kubiya-role:
apiGroups: ["*"]
resources: ["*"]
verbs: ["*"]
```

## image-updater-sa
    
Used in:
- CronJob `image-updater`

Total Permissions (via Role `deployment-updater`):

```
apiGroups: ["apps"]
resources: ["deployments"]
verbs: ["get", "patch"]
```

## default (dagger namespace)

Used in:
- DaemonSet `dagger-dagger-helm-engine`

Total Permissions:
No explicit permissions defined
