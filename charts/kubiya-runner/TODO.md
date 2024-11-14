1. Clarify: `registry-tls-secret` hardcoded?
2. Clarify: reason of `ImagePullPolicy` not set to `IfNotPresent` , fix if no objections
3. `tool-manager` remove `image: latest` and make sure other templates are aligned; put fixed and tested tag as default
4. Propose `tool-manager` repo fixes: `initContainers`: - name: `init-certs` image: `busybox`: put version
5. Where `automountServiceAccountToken=true` remove manual duplicate `volume` & `volumeMounts` (check path of mount match automounted)
6. Check and compare which `serviceAccount` used within all templates, including subchartss
7. Verify k8s entities which missing in this chart: compare with current runner installation single yaml (at least: image-updater, CronJobs, etc). Use `runner_v2_singleNamespace.tmpl.yaml` as reference.

# Low priority:

# TBD:

1.  Create minimal acceptable chart README
2.  Create full Chart.yaml as per helm guidelines
3.  Test chart locally: minimal testing, all green deployment, basic funcional tests, metrics presence in Prometheus, no errors in container logs, no restarts/not ready pods. 
4.  ADD legitimate Limits and requests to the chart (get from grafana pod dashboards)
5.  Install and configure OTA - add all checks client uses.
6.  Test chart against OTA
7.  Make sure no secrets are commited; check already present tls keys with Costa
8.  PR / Code review
9.  Prepare proper, packaged and versioned helm chart release

# Done:

# In Progress: 

1.  Verify, refactor and fix this chart. Consider helm best practices and remember about OTA checks.
2.  Add `kube-state-metrics` to the chart as dependency, traslate config from runner_v2_singleNamespace.tmpl.yaml to subchart values
3.  Add `otel-collector` to the chart as dependency, traslate config from `runner_v2_singleNamespace`.tmpl.yaml to subchart values
4.  Add `dagger` to the chart as dependency, traslate config from `runner_v2_singleNamespace`.tmpl.yaml to subchart values
5.  Make sure no diffs are left between chart and `runner_v2_singleNamespace.tmpl.yaml` (consider recent refactor).
6.  Unlock: make sure we have `tool-manager` fixed by devs; once done update its config in the chart.
7.  Ask devs about `tool-manager` existing helm char; consider it as a subchart?
8.  Ask for permission to repos and check `agent-manager` and `kubiya-operator` (helm chart? docs? versions?); 
