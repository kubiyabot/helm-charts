# Repository Structure

1. Helm Charts Repository: Contains the Helm charts and any shared resources.

```
helm-charts-repo/
├── charts/
│   ├── kubiya-runner/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   └── dagger-helm/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
└── README.md
```

2. Runners configs repo: contains the customer-specific configurations for the Helm charts.

```
customer-configs-repo/
├── clusters/
│   ├── customer1/
│   │   ├── helmrelease.yaml
│   │   ├── overrides.yaml
│   │   └── secrets/
│   │       └── sealed-secret.yaml
│   ├── customer2/
│   │   ├── helmrelease.yaml
│   │   ├── overrides.yaml
│   │   └── secrets/
│   │       └── sealed-secret.yaml
│   └── ...
└── README.md
```
`helmrelease` file contains:
    - Helm release definition
    - Overrides for the Helm chart
    - Secrets for the Helm release
  
Example:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: kubiya-runner
  namespace: default
spec:
  releaseName: kubiya-runner
  chart:
    spec:
      chart: kubiya-runner
      sourceRef:
        kind: GitRepository
        name: helm-charts
        namespace: flux-system
        ref:
          branch: main
  interval: 5m
  valuesFrom:
    - kind: ConfigMap
      name: customer-overrides
      valuesKey: overrides.yaml
```

Overrides are used to override customer specific values in the Helm chart:

```yaml
organization: "customer-org"
kubiyaAgentUUID: "123exxxx7-e89b-12d3-a456-xxxxxx"
nats:
  jwt: "customer-specific-jwt"
  secondJwt: "customer-specific-second-jwt"
  subject: "customer-specific-subject"
  org: "customer-specific-org"
toolManager:
  image:
    repository: "ghcr.io/kubiyabot/tool-manager"
    tag: "v1.20.0"
agentManager:
  replicas: 2
  env:
    - name: CUSTOM_ENV_VAR
      value: "custom-value"
  image:
    repository: "ghcr.io/kubiyabot/tool-manager"
    tag: "v1.20.0"
```

4. `FluxCD` Controller: Manages the deployment of the Helm charts to the Kubernetes clusters 
    - Installed along with runner in kubiya namespace customer's K8s cluster
    - Resources overhead (max. avg): 200 MB / 0.2 CPU

# How it works

1. The Helm Charts Repository is updated with the latest changes.
2. The FluxCD Controller detects the changes and applies them to the Kubernetes clusters by running `helm upgrade`
3. Secrets are encrypted (sealed) on our side and stored in the Runners configs repo.
4. Customer gets decryption keys from Kubiya - the only one key needed to decrypt all the secrets, customer specific.

# Deployment Process

1. Helm Charts Repository: Develop and maintain your Helm charts here. This repository is referenced by the customer configurations.
2. Customer Configurations Repository: Manage customer-specific configurations and overrides here. Each customer has its own directory with specific unique values, which are used to override the default values in the Helm chart.
3. FluxCD Setup: FluxCD is configured to monitor the customer configurations repository. It will apply the HelmRelease resources, which reference the Helm charts repository. FluxCD will also decrypt the secrets and apply them to the Kubernetes clusters.
4. Customer gets decryption key from Kubiya on initial deployment step - only one key needed to decrypt all the secrets (one key per customer).
5. Separation of Concerns: This setup allows to update Helm charts independently of customer-specific configurations, providing flexibility and modularity.


# Key Points

- Centralized configuration, secret and version source of truth.
- Modularity: Separate repositories allow for independent updates and maintenance of Helm charts and customer configurations.
- Security: Ensure that sensitive data in overrides.yaml is managed securely, potentially using tools like Sealed Secrets for encryption.
- FluxCD Integration: Use FluxCD to automate the deployment process, monitoring the customer configurations repository for changes.
- This approach provides a clean separation between the core Helm charts and customer-specific configurations, making it easier to manage and scale deployments.

# NATS

- As alternative to sealed secrets we can use already existing NATS as a per customer secrets manager.
- Configuration git repo can also be stored in NATS (e.g. key value or file storage)
