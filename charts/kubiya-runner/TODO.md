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
- [?] Make sure no diffs are left between chart and `runner_v2_singleNamespace.tmpl.yaml` (consider recent refactor).
- [ ] Once dev fixes `tool-manager` - update image and discovery svc in chart.
- [ ] Verify all resources from runner installation rendered yaml present.
- [?] Verify all configurables from `runner_v2_singleNamespace.tmpl.yaml` preserved.
- [x] Add what was surely missing in base chart draft: at least jobs like image-updater were not in base chart draft.
- [ ] Create minimal chart README with and compatibility table

## Nice to have

- [ ] Detailed chart README.
- [ ] Align Chart.yaml as per helm guidelines.
- [ ] Actual Limits/Requests for all containers, including subcharts (get from grafana pod dashboards)

## Testing

- [ ] Render chart with prod vars.
- [ ] Deploy locally with runner connected to cloud,
- [ ] Test chart locally:
    - [ ] No failed pods, jobs, restarts, not ready pods. 
    - [ ] Basic functional/integrational test
    - [ ] Metrics, logs, telemetry made it to the centralized storage (Prometheus, etc).
    - [ ] Image updater works.
    - [ ] Chart: packaging, upgrade, rollback, delete, reinstall - all works.
- [ ] Install and configure OTA policies to reproduce client's original validation violations list using old original runner template.
- [ ] Test new chart against same cfg, make sure no validation errors. Notify SA.

## Before going to prod

- [ ] NO SECRETS in chart and it's git commit history - create a new repo? check already present tls keys with Costa
- [ ] PR / Code review
- [ ] Prepare packaged, versioned helm chart .gz release. Upload it and default containers to artifact storage.
- [ ] Internal announcement.
- [ ] Make sure pull policies are set correctly for all containers. Ensure 'Always' is really needed where used; change to 'IfNotPresent' if possible.

## Fixes and Improvements

1. Clarify: `registry-tls-secret` hardcoded?
2. Clarify: reason of `ImagePullPolicy` not set to `IfNotPresent` , fix if no objections
3. `tool-manager` remove `image: latest` and make sure other templates are aligned; put fixed and tested tag as default
4. `tool-manager` fix: repos / `initContainers` / `init-certs` -> `busybox` remove latest or replace with ImagePullSecrets, ServiceAccountTokenMount or ConfigMap -> ENV_VAR or ...
5. Where `automountServiceAccountToken=true` remove manual duplicate `volume` & `volumeMounts` (check path of mount match automounted)
Must check and fix if needed before release:
6. Check and compare which `serviceAccount` used within all templates, including subcharts
7.  Ask devs about `tool-manager` existing helm char; consider it as a subchart?
8.  Ask for permission to repos and check `agent-manager` and `kubiya-operator` (helm chart? docs? versions?); 
9.  
# - Out of Runner into Helm scope -

## General improvements and further development

1. !!! NATS intermediate for metrics delivery to managed Prometheus via otel-collector with custom made plugin -> Prometheus (Azure native, envoy). Remove NATS: our own custom otel-collector exporter to NATS, NATS and its multiple cfg entities, connector from NATS to Prometheus. Win everywhere with zero coding required: more streamlined delivery, well-known stable components, cost cuts, single points of failure cuts, scalability from the box, no bus factor.
2.  Image Updater / Continous Delivery: `Argo CD`, Flux https://fluxcd.io/flux/concepts/
3.  `cert-manager`, `istio`, `vault` - service mesh + secuirty + secret and conbf vars storage per client
   

## Points of further improvements (list needs to be reviewed and prioritized):

3.  Monitor spikes in observability data; cut unnecessary metrics collection
4.  Consider necessity and effort for optional extension:  `node-exporter`, more `kube-state-metrics` metric, `kubelet` / k8s API wider metrics.
5.  Ensure all kubiya services has `/health` and `/metrics`.
6.  Alerting on limits reached / throtling / OOM
8.  scaling - think for tomorrow and today if already needed 
9.  Granularity increase - extract subchart `tool-manager`, `agent-manager`, `operator`, `jobs` and etc
10. Custom image Updater replacement. Why: no tracability and visibility of image we have in all prod runners. Custom code. Replacement: `Argo CD Image Updater`, `kubectl rollout restart `, 
11. Secrets storage and population per runner environment - vault - can be combined with env-specific  plain text config storage as well
12. Tune metrics gathering: measure total count, volume, cardinality, scrape success, performance. Enable/disable default exporters optimization. No duplicates from diff metrics sources, no high cardinality, no spikes. Reasonable retention periods, long term storage, aggregations. Daily cost alerts/monthly cost reports. $ of infra per client metrics (and infra in general)
13. Traces, logs, metrics, alerts are cross-correlated.
