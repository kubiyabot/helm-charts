# The Problem

- **Privileged Container Requirement:**  
  Dagger cannot function without GOD MODE ON (run as a privileged/root container, with ALL_CAPS and hostPath). This is a security red flag, especially for SaaS/multi-tenant.
  (With this set of permissions Dagger has full root access to k8s node it runs on. Enterprise pentesterers, badactors, can do (or already did?) will And, if badactor, or 
- **vCluster**
  vCluster by default isolates only parent k8s cluster control plane. It have optional isolated mode, but it will not run containers in GOD MODE by default. No profit, but extra complexity for dev and ops, resource overhead, performance pentalties, etc..
- **Host Access:**  
  Dagger uses BuildKit/Docker-in-Docker patterns, requiring low-level control, risking host compromise if broken out.
- **Multi-Tenancy:**  
  In SaaS, multiple customers' workloads may share a node. An escape in one privileged Dagger container could affect others. May have CRITICAL coesequences. 
- **OnPremise**
  Very possible incompatibility of Kubiya Runner due to level of privilidges will most enterprise env with their common security restrictions (was the case twice at least: OPA - <forgotten_client_name>, Openshift customer). 
- **SOC2/Big Selling Points**
  Not compliant with above.
- **AWS/GCP/Azure Marketplaces**
  Mostly not compatible with GOD MODE containers.
  