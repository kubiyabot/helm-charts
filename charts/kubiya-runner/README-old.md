# Kubiya Runner Helm Chart

This repository contains the Helm chart for deploying the Kubiya Runner, a key component of the Kubiya platform for orchestrating and managing automation workflows.

## Repository Structure

```
kubiya-helm-charts/
├── charts/
│   └── kubiya-runner/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── templates/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   └── ...
│       ├── charts/
│       └── README.md
├── .helmignore
└── README.md
```

## Prerequisites

- Kubernetes 1.16+
- Helm 3.0+

## Installation

To install the chart with the release name `my-release`:

```bash
helm repo add kubiya https://kubiya.github.io/helm-charts
helm install my-release kubiya/kubiya-runner
```

## Configuration

The following table lists the configurable parameters of the Kubiya Runner chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `kubiya/runner` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

For more information on configurable parameters, please refer to the [values.yaml](./charts/kubiya-runner/values.yaml) file.

## Contributing

We welcome contributions to the Kubiya Runner Helm chart. Please read our [Contributing Guide](CONTRIBUTING.md) for more information on how to get started.

## License

This project is licensed under the [Apache License 2.0](LICENSE).
