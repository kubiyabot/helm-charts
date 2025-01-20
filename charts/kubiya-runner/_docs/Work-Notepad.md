# Customer Runners

# Stage I - Helm Chart

## Tasks

- [x] Setup local dev environment, get all cloud tokens and access needed for complete testing.
- [x] Move all runner components to single namespace, remove cluster-wide roles, minimize permissions for all resources across all runner components.
- [x] Fix missing `kube-state-metrics`.
- [x] Limit metrics gathering to just enough set for runner-only components (no other data from client namespaces or nodes).
- [x] Verify, refactor and fix existing parts of chart draft implementation.
- [x] Review all `ScrapeConfigs` in `otel-collector`: verify metrics delivery works. Ensure scrapes are consistent with pre-defined and limited scope to satisfy 1st stage monitoring goals. Confirm k8s and runner's metadata is appended. Set intervals (15 to 60s).
- [x] Test implementation of #1-7 - prepare template and install runner with it. Verify all components work and metrics are delivered.
- [x] Debug `tool-manager` failing to run in single namespace. Propose fix.
- [x] Add `kube-state-metrics` to the chart as dependency, translate fixed config from runner_v2_singleNamespace.tmpl.yaml as subchart values.
- [x] Add `dagger` to the chart as dependency, translate config from `runner_v2_singleNamespace.tmpl.yaml` to subchart values.
- [x] Investigate why runner cannot be installed in bynder environment. Propose quick fix to unlock POC, fix permanently in chart (see below).
- [x] Add `otel-collector` to the chart as dependency, translate its config from `runner_v2_singleNamespace.tmpl.yaml` to subchart values.
- [x] Ensure no diffs remain between chart and `runner_v2_singleNamespace.tmpl.yaml` (consider recent refactor).
- [x] Once dev fixes `tool-manager` - update image and add `dagger` discovery service to the chart.
- [x] Verify all configurables from `runner_v2_singleNamespace.tmpl.yaml` are preserved.
- [x] Add missing components from base chart draft: at least CronJob `image-updater`.
- [x] Update README to meaningful state (add compatibility table if needed).
- [x] Check all `serviceAccount` references are present within all templates, including subcharts, and not hardcoded. Tune permissions for least privileges while maintaining functionality.
- [?] Review all TODOs.
- [x] Add dagger headless service for tool-manager discovery/balancing to runner chart as vendor's subchart has no services templates.
- [x] Add `blackbox-exporter` as dependency, configure scraping of runner components for health overview. Probe dagger and kubiya-operator which don't have metrics exposed.
- [x] Create new dashboards based on `blackbox-exporter`, `kube-state-metrics` for health overview, and detailed app view based on agent-manager and tool-manager dashboards.
- [x] Add Grafana dashboards as code.
- [x] Add oauth2-capable `prometheus-exporter` to push remote_writes directly to Prometheus.
- [x] Make k8sattributes metadata attached to scraped metrics.

## Testing

- [x] Render chart with prod vars.
- [x] Verify all resources from runner installation rendered yaml are present in the chart.
- [x] Deploy locally with runner connected to cloud.
- [x] Test chart locally:
    - [x] No failed pods, jobs, restarts, or not-ready pods.
    - [x] Basic functional/integration testing.
    - [x] Metrics, logs, telemetry reach centralized storage (Prometheus, etc).
    - [x] Image updater works.
    - [x] Chart: packaging, upgrade, rollback, delete, reinstall - all work.
    - [x] Tool manager -> dagger discovery.
    - [x] Service account permissions.

## Additional tasks

- [x] Move dagger RBAC and headless service to subchart, merge values.yaml, bump version, changelog update, test, build package
- [x] Add liveness probes for `tool-manager` and `agent-manager` to templates (supported in app code now)
- [x] Remove container port from `kubiya-operator` deployment

## Before Going to Production

- [x] Add Grafana dashboards as code.
- [x] NO SECRETS in chart and its git commit history (create new repo or use `push -f`). Discuss existing TLS keys with Costa.
- [x] PR / Code review.
- [x] Prepare packaged, versioned helm chart `.gz` release. Upload it and default containers to artifact storage.
- [x] Internal announcement.

## Fixes and Improvements

- [?] `tool-manager` fix: repos / `initContainers` / `init-certs` -> `busybox` remove latest or replace with `ImagePullSecrets`, `ServiceAccountTokenMount` or ConfigMap -> ENV_VAR or ...
- [x] `tool-manager`: remove `image: latest` and ensure other templates are aligned; set fixed and tested tag as default.
- [x] ~Ask devs about `tool-manager` existing helm chart; consider it as a subchart?~ ---> abandoned chart.
- [x] Add dagger as a forked repo to runner chart - kustomize does not support vars directly :(
- [x] Align `Chart.yaml` as per helm guidelines.
- [x] Check repos `agent-manager` and `kubiya-operator` for helm chart (permission required).
- [x] Clarify: `ImagePullPolicy` not set to `IfNotPresent` for some containers, fix if no objection.
- [x] Clarify: Is `kubiya-runner-registry-tls-secret` hardcoded? Improve?
- [x] Fix mounts for dagger folders with kustomize
- [x] Make k8sattributes metadata attached to scraped metrics.
- [x] Where `automountServiceAccountToken=true` remove manual duplicate `volume` & `volumeMounts` (check if mount path matches automounted).

# Stage II - Direct Remote Write to Prometheus(es) 

## Tasks & Testing

- [x] Configure Azure Managed Prometheus to work remote_writes
  - [x] Apply config changes on new prometheus instance
  - [x] Test data sent went to prometheus and visible in Grafana
- [x] Add Grafana `alloy`
  - [x] Create & test minimal config with export to Azure Prometheus
  - [x] Add as subchart to runner
    - [x] Translate `otel-collector` config to Grafana Alloy
    - [x] Test: make sure all data with correct labels sent to Azure Prometheus from local cluster
    - [x] Test multiple runner instances with different labels
    - [x] Remove `blackbox-exporter` as dependency, replace with Grafana Alloy integration
    - [x] Make scraping of runners components exporters precise as now unbolocked by `otel-collector` bug
  - [x] ~Add tested grafana alloy remote write -> Azure Prometheus to `otel-collector`~
  - [x] Remove `otel-collector` as dependency OR leave it disabled by default OR make it frozen branch
  - [x] Create basic documentation for Grafana Alloy integration
  - [x] Based on full metrics set obtained via Alloy - finalize dashboards for remote runners
    - [x] Fix already existed with missing `blackbox-exporter`
    - [x] Add Alloy self monitoring dashboard to see all runners `alloy` main metrics
    - [x] Runners Health Overview
 
# Next Steps

## Environments & Security

- [ ] Azure Prometheus/Keys/Grafana: separate prod from staging; change endpoint for prod
- [ ] Azure Key: Verify Permissions and provide frontend with `overrides.yaml` including all azure things
- [ ] ClusterRole & Scope: with PR to repo `tool-manager` got non-default cluster wide admin, and default cluster wide PVC management permissions. This should be reviewed and mentioned in docs.

## Development & delivery guidance

- [ ] [ToDo] Review all PR: pending
- [ ] [ToDo] Fix tool manager / dagger / Tool-manager for ARM? `[x]`
- [ ] [ToDo] Review & redo all merged where needed (e.g. growing mess in `values.yaml`) `[x]`
- [ ] [ToDo] Merge to main; protect it; set minimum 2 reviewers required;
- [ ] [ToDo] Release v1.0; cleanup branches; fix CI; upload .tgz
- [ ] [Devs assistance] override vs Set Provide dev with override example: correct one, without mess and invalid values passing `[x]`
- [ ] [Devs assistance] packaging, versioning, upgrade procedures `[x]`
- [x] [Devs assistance] Configuration `--set a=foo b=bar .. ... ... .... z=omfg` use `-f override_customer_name.yaml`, store in NATS or git repo (with sealed secrets)

## Observability Best Practices Talks

- [ ] `/metrics` - ok 200 vs if response.t < 60 -> ok 200 
- [ ] `readiness` vs `liveness` vs `startup` - scaling/load balancing/pod lifecycle; `health` vs `healtz`; `http_request_total`, `http_status_code`, `xxx_xxx_http_request_total` and etc. `[x]`
- [ ] CRDs, pod/helm lebeling, ServiceMonitor, Blackbox eporter for user workloads, etc. `[x]`

## Costs & Scale

- [ ] Create chart and alert on metric volume increase & threshold volume reached
- [ ] All setup cost charts in Grafana, mainly Azure Prometheus Instance cost
- [ ] Separate all Staging/Production

## Leftovers

- [ ] Export tested AZ resources chain for storing as-a-code in Terraform or at least in git repo (make sure no secrets committed)
- [ ] Dashboard merge/leftovers
- [ ] Dashboard -> All Runners Status linked to Runner Health Overview
- [ ] Reduce scope to namespace level metrics only precreated RBAC and Se4rviceAccount, make all k8s meta required permissions are given (check alloy default RBAC)
  - [ ] Consider remote config for oauth2 client and remote endpoint url - security measure, centralization + easy to switch off/on
  - [ ] Current alloy `deplopy` model - replicates `otel-collector` (deployment). Reconsider as we start get into diff deployment scenarios.
- [ ] Update README `[!]`
  - [ ] Alloy: take screenshot of dashboard graph & other(?)
  - [ ] Component labels used (!)
  - [ ] Grafana dashboards set;
  - [ ] Remote Writes
  - [ ] Azure cfg
  - [ ] JIRA TASKS / CHANGELOG
- [ ] Check as-is transfered from old template volume postfixes for dagger imnages - should be removed or moved to hostPath not volumeMount?
- [ ] UUID and other params pass to runner conflicts from recent PR

## Not Actual? 

- [ ] Current `image-updater` should be replaced. Discuss with Costa. `runAsUser: 0`.
- [ ] New RBAC review: namespaces, cluster scope, permissions, optional vars.
- [ ] Reduce labels collection to only necessary ones for `runner_app_pods` discovery relabeling

# Stage III

# CI/CD 

- [ ] Split runner chart into multiple charts:
  - [ ] agent-manager
  - [ ] tool-manager
  - [ ] kubiya-operator

- [ ] Configuration (overrides, values, secrets) generation and storage
- [ ] Centralized deployments (image updater not suitable anymore with helm)
- [ ] Github protected `main` branch, enforced PRs
- [ ] Artifact storage for containers, dependecies, helm charts, libs.
- [ ] Chart CI
  - [ ] helm-docs
  - [ ] helm-lint
  - [ ] helm-test
  - [ ] helm-package
  - [ ] helm-push
  - [ ] helm-lint-and-install
  - [ ] helm-lint-and-test