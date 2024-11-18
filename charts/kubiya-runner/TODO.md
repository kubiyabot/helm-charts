## Runner Helm Chart

## - TODO - The Must

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
- [ ] Update README to meaningful state (add compatibility table if needed).
- [x] Check all `serviceAccount` used present within all templates, including subcharts, and not hardcoded. tune permission for least privileges while keeping it functional
- [ ] Go through TODOs
- [ ] Add dagger headless service for tool-manager discovery/balancing to runner the chart as vendor's subchart has no services templates.

## Nice to have

- [ ] Detailed chart README.
- [ ] Align `Chart.yaml` as per helm guidelines.
- [ ] Actual Limits/Requests for all containers, including subcharts (get from `Grafana` pod dashboards)

## Testing

- [x] Render chart with prod vars.
- [ ] Verify all resources from runner installation rendered yaml are present in the chart.
- [ ] Deploy locally with runner connected to cloud,
- [ ] Test chart locally:
    - [ ] No failed pods, jobs, restarts, not ready pods. 
    - [ ] Basic functional/integrational test
    - [ ] Metrics, logs, telemetry made it to the centralized storage (Prometheus, etc).
    - [ ] Image updater works.
    - [ ] Chart: packaging, upgrade, rollback, delete, reinstall - all works.
    - [ ] Tool manager -> dagger discovery
    - [ ] Service account permissions

## OTA

- [ ] Install and configure OTA policies to reproduce client's original validation violations list using old original runner template.
- [ ] Test new chart against same cfg, make sure no validation errors. Notify SA.

## Before going to prod

- [ ] Current `image-updater` should be replaced. Discuss with Costa. `runAsUser: 0`
- [ ] NO SECRETS in chart and it's git commit history (create new repo or use `push -f`). Dissccuss existing tls keys with Costa
- [ ] PR / Code review.
- [ ] Prepare packaged, versioned helm chart `.gz` release. Upload it and default containers to artifact storage.
- [ ] Internal announcement.

## Fixes and Improvements

1. Clarify: `registry-tls-secret` hardcoded? Improve?
2. Clarify: `ImagePullPolicy` not set to `IfNotPresent` for some containers, fix if no objection. 
3. `tool-manager` remove `image: latest` and make sure other templates are aligned; put fixed and tested tag as default
4. `tool-manager` fix: repos / `initContainers` / `init-certs` -> `busybox` remove latest or replace with `ImagePullSecrets`, `ServiceAccountTokenMount` or ConfigMap -> ENV_VAR or ...
5. Where `automountServiceAccountToken=true` remove manual duplicate `volume` & `volumeMounts` (check path of mount match automounted)
2. Ask devs about `tool-manager` existing helm char; consider it as a subchart?
3. Check repos `agent-manager` and `kubiya-operator` for helm chart (permission required)

