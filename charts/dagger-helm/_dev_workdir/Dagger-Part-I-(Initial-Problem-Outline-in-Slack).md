# Initial Problem Outline in Slack

## From Slack group chat 
20/02/2025
```
Hi Team, I’d like to highlight potentially major business issue we may have due to excessive Customer Runners's permisons/access level.
Many of our enterprise clients (roughly half?) opt for our on-premise deployment model - which is normally due to extra security and privacy requirements. However, current `Customer Runner` installation requires a permission set that grants it unrestricted control over the k8s cluster in which it is deployed.
This may raise significant security concerns, especially for enterprises that specifically chose the on-premise setup for enhanced isolation. Our Runner deployment may not pass automated (like earlier case client with OPA Gatekeeper) or manual security reviews, meaning customers may need to invest extra effort to restrict Runner access to their workloads and data. Also, it might require additional risk assessments / preparation steps before proceeding to contract signing meaning delays, or could become a deal-breaker for some.
While working on packaging Runner components into helm chart, thanks to Costa’s mediation with dev team, we managed to compact Runner into single namespace. Additionally I've cut excessive permissions where possible, reduced access scopes from cluster wide to own namespace only.
Later, we had to reintroduce full-cluster control for tool-manager, gated by user acknowledgment (though, realistically, I guess it’s no so “optional”..).
Here is main excessive permissions list that we provide in Runner chart to it's components:
1. tool-manager full cluster control via "optional" ClusterRole
2. tool-manager full control on all cluster's persistent volumes via default CluserRole
3. dagger daemonset sits with root in privileged pod on all nodes + has hostPath mounts.
4. image-updater - full RBAC & PVC control on cluster via default CluserRole (this one will gone when we switch to new deployments).
```