## Runner Helm Chart

## TODO - The Must

- [x] Setup local dev environment, get all cloud tokens and access needed for complete testing.
- [x] Move all runner components to single namespace, remove cluster wide roles, minimize permissions for all resources across all runner components.
- [x] Fix missing `kube-state-metrics`.
- [x] Limit metrics gathering to just enough set for runner only components (no other data from client namespaces or nodes)
- [x] Verify, refactor and fix existing parts of chart draft implementation.
- [x] Review all `ScrapeConfigs` in `otel-collector`: metrics delivery actually works. Scrapes are consistent, with pre-defined and limited scope to satisfy 1st stage monitoring goals. Ensure k8s and runner's meta appended. Intervals set (15 to 60s). 
- [x] Test implememnation of #1-7 - prepare template and install runner with it. Make sure all components works, metrics delivered.
- [x]  Debug `tool-manager` failed to run in single namespace. Propose fix
- [x] Add `kube-state-metrics` to the chart as dependency, translate fixed config from runner_v2_singleNamespace.tmpl.yaml as subchart values.
- [x] Add `dagger` to the chart as dependency, translate config from `runner_v2_singleNamespace`.tmpl.yaml to subchart values.
- [x] Investigate runner cannot be installed on bynder environment. Propose quick fix to unlock POC, fix permanently in chart (see below)
- [x] Add `otel-collector` to the chart as dependency, translate its config from `runner_v2_singleNamespace.tmpl.yaml` to subchart values
- [x] Make sure no diffs are left between chart and `runner_v2_singleNamespace.tmpl.yaml` (consider recent refactor).
- [x] Once dev fixes `tool-manager` - update image and add `dagger` discovery service to the chart.
- [x] Verify all configurables from `runner_v2_singleNamespace.tmpl.yaml` preserved.
- [x] Add what was missing in base chart draft: at least CronJob `image-updater`.
- [x] Update README to meaningful state (add compatibility table if needed).
- [x] Check all `serviceAccount` used present within all templates, including subcharts, and not hardcoded. tune permission for least privileges while keeping it functional
- [?] Go through TODOs
- [x] Add dagger headless service for tool-manager discovery/balancing to runner the chart as vendor's subchart has no services templates.
- [x] Add blackbox-exporter as dependency, configure scraping of runner components for health overview. Probe dagger, kubiya-operator which doesn't have metrics exposed.
- [x] Create new dashboards based on blackbox-exporter, kube-state-metrics for health overview, and app ditailed view based on agent-manager and tool-manager dashboards.
- [x] Add Grafana dashboards as a code.
- [ ] Add healthchecks.io dashboard visualization component.
- [ ] Add oauth2 capable Prometheus exporter to push remote_writes directly to Prometheus.
- [ ] Make k8sattributes metadata attached to scraped metrics.

## Testing

- [x] Render chart with prod vars.
- [x] Verify all resources from runner installation rendered yaml are present in the chart.
- [x] Deploy locally with runner connected to cloud.
- [x] Test chart locally:
    - [x] No failed pods, jobs, restarts, not ready pods. 
    - [x] Basic functional/integrational test
    - [x] Metrics, logs, telemetry made it to the centralized storage (Prometheus, etc).
    - [x] Image updater works.
    - [x] Chart: packaging, upgrade, rollback, delete, reinstall - all works.
    - [x] Tool manager -> dagger discovery
    - [x] Service account permissions

## OTA

- [ ] Install and configure OTA policies to reproduce client's original validation violations list using old original runner template.
- [ ] Test new chart against same cfg, make sure no validation errors. Notify SA.

## Before going to prod

- [ ] Add Grafana dashboards as a code
- [x] Current `image-updater` should be replaced. Discuss with Costa. `runAsUser: 0`
- [ ] NO SECRETS in chart and it's git commit history (create new repo or use `push -f`). Dissccuss existing tls keys with Costa
- [ ] PR / Code review.
- [ ] Prepare packaged, versioned helm chart `.gz` release. Upload it and default containers to artifact storage.
- [ ] Internal announcement.

## Fixes and Improvements

- [x] Carify: `kubiya-runner-registry-tls-secret` hardcoded? Improve?
- [x] Clarify: `ImagePullPolicy` not set to `IfNotPresent` for some containers, fix if no objection. 
- [x] `tool-manager` remove `image: latest` and make sure other templates are aligned; put fixed and tested tag as default
- [?] `tool-manager` fix: repos / `initContainers` / `init-certs` -> `busybox` remove latest or replace with `ImagePullSecrets`, `ServiceAccountTokenMount` or ConfigMap -> ENV_VAR or ...
- [ ] Where `automountServiceAccountToken=true` remove manual duplicate `volume` & `volumeMounts` (check path of mount match automounted)
- [x] ~Ask devs about `tool-manager` existing helm char; consider it as a subchart?~ ---> abandoned chart
- [x] Check repos `agent-manager` and `kubiya-operator` for helm chart (permission required)
- [x] Align `Chart.yaml` as per helm guidelines.

