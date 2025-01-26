
# [DRAFT] Calculations for cumulative health score, based on available metrics that we have for each component.

**This is draft document. There are no dashboards or alerts based on this approach.**

## Grouped metrics into tiers of criticality based on their impact on the app’s health

1.	Tier 1 – Critical Signals (40-50%)
•	Metrics that directly indicate service availability or functionality (e.g., `probe_success` from Blackbox).
•	Rationale: If this fails, the app is fundamentally broken.

2.	Tier 2 – Degraded Performance Signals (20-30%)
•	Metrics showing performance or error trends (`http_requests_total`, error rates).
•	Rationale: Failures here mean reduced quality but not total failure.

3.	Tier 3 – Kubernetes State Signals (10-20%)
•	Pod readiness (`kube_pod_status_ready`), restarts (`kube_pod_container_status_restarts_total`).
•	Rationale: These are indirect signals; restarts or readiness issues could still allow the app to function, but stability is questionable.

## Defined thresholds for each metric to determine “healthy” or “unhealthy” states.

1.	`probe_success` (Blackbox) → Critical Metric (40%)
•	1: Healthy
•	0: Unhealthy
•	Weight: 0.4

2.	Error Rate (`http_requests_total`) → Performance Metric (30%)
•	>5% errors → Degraded
•	>10% errors → Critical
•	Weight: 0.3

3.	Pod Readiness (`kube_pod_status_ready`) → Stability Metric (20%)
•	100% ready → Healthy
•	<80% ready → Degraded
•	Weight: 0.2

4.	Pod Restarts (`kube_pod_container_status_restarts_total`) → Stability Metric (10%)
•	0 restarts → Healthy
•	>3 restarts per 5m → Degraded
•	Weight: 0.1

## Each metric contributes a normalized score based on its threshold

•	Healthy metrics contribute full weight (1.0)
•	Degraded metrics contribute partial weight (0.5)
•	Unhealthy metrics contribute zero weight (0.0)

•	Blackbox: probe_success = 1 → 0.4 * 1 = 0.4
•	HTTP Errors: 5% errors → 0.3 * 0.5 = 0.15

•	Pod Readiness: 90% ready → 0.2 * 0.75 = 0.15
•	Pod Restarts: 1 restart → 0.1 * 0.8 = 0.08

Final Health Score: 0.4 + 0.15 + 0.15 + 0.08 = 0.78

# Handling Disparity in Metrics Between Components

Components with fewer health signals (e.g., kube-state-metrics only) shouldn’t unfairly drag down the overall health score compared to those with more metrics (e.g., Blackbox, app exporter).

## Normalize Per-Component Health Scores

Instead of directly summing all signals into one formula, scoring break down per-component first.
	
1.	Group Components Based on Available Metrics:
•	Full Observability Group: Metrics from Blackbox, App Exporter, Kubernetes State.
•	Partial Observability Group: Metrics from Kubernetes State only.

2.	Per-Component Health Formula

***Full Observability Component***
```
(
  (probe_success * 0.4) +
  (1 - error_rate * 0.3) +
  (pod_ready_ratio * 0.2) +
  (1 / (1 + pod_restarts) * 0.1)
)
```
***Partial Observability Component***

```
(
  (pod_ready_ratio * 0.7) +
  (1 / (1 + pod_restarts) * 0.3)
)
```
## Aggregate Component Scores into Namespace-Level Score

avg by (namespace) (
  (
    (component_1_score * 0.5) +
    (component_2_score * 0.5)
  )
)```

## Missing Metrics Fallback

If a metric (e.g., Blackbox probe_success) is entirely missing for a component, substitute a neutral score (e.g., 0.5) instead of zero to prevent unfair penalty:

```
if absent(probe_success{namespace="$namespace"}) then 0.5
```

## Final Aggregated Health Score

Aggregate all components into a namespace-wide health score:

```
(
  avg_over_time(component_1_health[5m]) * 0.5
  + avg_over_time(component_2_health[5m]) * 0.5
)
by (namespace, runner)
```

# Component-Level Health State Timeline


## Blackbox (Probe Success)

```
avg_over_time(probe_success{namespace="$namespace", runner="$runner"}[5m])
```

If a metric (e.g., Blackbox probe_success) is entirely missing for a component, substitute a neutral score (e.g., 0.5) instead of zero to prevent unfair penalty:

### Tranform into State Labels

```
label_replace(
  (avg_over_time(probe_success{namespace="$namespace", runner="$runner"}[5m]) == 1) * 1, "state", "Healthy", "", ""
) or label_replace(
  (avg_over_time(probe_success{namespace="$namespace", runner="$runner"}[5m]) == 0) * 1, "state", "Critical", "", ""
)
```

## App-Specific Metric (HTTP Error Rate)
```
1 - avg(rate(http_requests_total{namespace="$namespace", runner="$runner", status=~"5.."}[5m]))
```
### Pod Readiness
```
sum(kube_pod_status_ready{namespace="$namespace", runner="$runner", condition="true"}) 
/ 
count(kube_pod_status_ready{namespace="$namespace", runner="$runner"})
```
### Pod Restarts
```
1 / (1 + sum(rate(kube_pod_container_status_restarts_total{namespace="$namespace", runner="$runner"}[5m])))
```

# Queries for State Timeline & Status History

Purpose: Display the aggregated health score over time for each namespace/cluster.

## PromQL Query:

```
avg by (namespace, runner) (
  (
    (avg_over_time(probe_success{namespace="$namespace", runner="$runner"}[5m]) * 0.4)
  + (1 - avg(rate(http_requests_total{namespace="$namespace", runner="$runner", status=~"5.."}[5m])) * 0.3)
  + (sum(kube_pod_status_ready{namespace="$namespace", runner="$runner", condition="true"}) 
      / count(kube_pod_status_ready{namespace="$namespace", runner="$runner"}) * 0.2)
  + (1 / (1 + sum(rate(kube_pod_container_status_restarts_total{namespace="$namespace", runner="$runner"}[5m]))) * 0.1)
  )
)
```

## Transform into discreate state:

```
label_replace(
  (avg by (namespace, runner) (...) > 0.8) * 1, "state", "Healthy", "", ""
) or label_replace(
  (avg by (namespace, runner) (...) > 0.6 and avg by (namespace, runner) (...) <= 0.8) * 1, "state", "Degraded", "", ""
) or label_replace(
  (avg by (namespace, runner) (...) <= 0.6) * 1, "state", "Critical", "", ""
)
```

Measure rates:

- >0.8 → Healthy
- 0.6–0.8 → Degraded
- <0.6 → Critical
