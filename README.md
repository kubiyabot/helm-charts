# Kubiya Helm Charts

This repository contains Helm charts for Kubiya applications.

## Available Charts

Currently, this repository hosts the following charts:

- [kubiya-runner](./charts/kubiya-runner/README.md): Helm chart for deploying Kubiya Runner.

## Usage

To use the charts from this repository, follow these steps:

1. Add the Helm repository:
   ```
   helm repo add kubiya https://kubiyabot.github.io/helm-charts
   ```

2. Update your Helm repositories:
   ```
   helm repo update
   ```

3. Install a chart:
   ```
   helm install my-release kubiya/kubiya-runner
   ```

## Development

To develop or modify these charts:

1. Clone this repository:
   ```
   git clone https://github.com/kubiyabot/helm-charts.git
   ```

2. Make your changes to the desired chart under the `charts/` directory.

3. Update the chart version in the respective `Chart.yaml` file.

4. Commit your changes and push to the main branch.

5. The GitHub Actions workflow will automatically package and release the updated charts.

## Contributing

We welcome contributions to improve our Helm charts. Please feel free to submit issues or pull requests.

## License

This project is licensed under the [Apache License 2.0](LICENSE).
