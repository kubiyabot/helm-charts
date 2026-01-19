# Action Plan

- [Proposed Solutions - Kata - Action List](#proposed-solutions---kata---action-list)
	- [Why GKE Autopilot **won’t work right now**](#why-gke-autopilot-wont-work-right-now)
	- [Kata Containers as a "Wrapper" for Dagger (On‑Prem + SaaS SRE Layer)](#kata-containers-as-a-wrapper-for-dagger-onprem-saas-sre-layer)
	- [Migration Template (Ready for Slides)](#migration-template-ready-for-slides)
	- [Extra Questions](#extra-questions)
	- [Other Sandbox Alternatives](#other-sandbox-alternatives)
- [Proposed Solutions - Kata - Action List](#proposed-solutions---kata---action-list-1)
	- [1. Why GKE Autopilot **won’t work right now**](#1-why-gke-autopilot-wont-work-right-now)
	- [2. Kata Containers as a "Wrapper" for Dagger (On‑Prem + SaaS SRE Layer)](#2-kata-containers-as-a-wrapper-for-dagger-onprem-saas-sre-layer)
	- [4. Migration Template (Ready for Slides)](#4-migration-template-ready-for-slides)
	- [5. Extra Questions](#5-extra-questions)
	- [6. Other Sandbox Alternatives](#6-other-sandbox-alternatives)
- [Dagger in Kata Containers: Cloud Marketplace Compatibility](#dagger-in-kata-containers-cloud-marketplace-compatibility)
	- [Brief Summary](#brief-summary)
	- [Kata + Dagger Compatibility Matrix](#kata--dagger-compatibility-matrix)

# Proposed Solutions - Kata - Action List

|  | SaaS (Our GKE Cloud) | On‑Prem (Client's Cluster) |
|---|---|---|
| **Quick fix (<3 months)** | ➜ **Dedicated node‑pool in _Standard_ GKE** with taint `dagger=true` → allow `privileged`, `hostPath`, root. Use **one cluster per customer** for isolation.<br>(Autopilot is off the table – it blocks `privileged`/`hostPath`) | ➜ **Use `kata` RuntimeClass.** Dagger runs “docker‑in‑docker” inside a micro‑VM; the host stays clean. Kata supports **vanilla K8s, OpenShift, EKS Anywhere, AKS preview**, etc. |
| **Risks** | Still running root containers; need per‑tenant cluster isolation | +10–15 % CPU / +100 MiB RAM per pod; need to install Kata |
| **Mid‑term plan (3–9 months)** | 1️⃣ Migrate to **rootless BuildKit** or **Sysbox** (if LLB cache loss is acceptable).<br>2️⃣ Drop `ALL` capabilities, reduce to `NET_ADMIN`, `SYS_ADMIN`. | Stick with Kata/Firecracker; optionally explore **KubeVirt pod‑VMs** for max isolation |
| **Long‑term** | Ditch Dagger completely; replace with Tekton/Buildah or a custom runner | Same; or keep Kata+BuildKit as sandbox fallback |

## Why GKE Autopilot **won’t work right now**

* **Autopilot blocks** `hostPath` and `privileged` for all but certified “partner workloads.”  
* Becoming a partner takes **3–6 months** and lots of vendor back‑and‑forth.  
* Even if whitelisted, you can’t manage the node OS → debugging cache or kernel tweaks becomes painful.

**Conclusion:** the fastest secure path for now is **Standard GKE** with:

- dedicated node pool (`dagger=true`)
- `PodSecurityAdmission: privileged`
- NetworkPolicy isolation

## Kata Containers as a "Wrapper" for Dagger (On‑Prem + SaaS SRE Layer)

**What it gives**

* Runs containers in **micro‑VMs** → full kernel isolation; root escapes are blocked.  
* Supports `--privileged`, `docker-socket`, and `ALL` capabilities **inside** the VM.  
* Just declare a `RuntimeClass: kata` — no change to your main k8s stack.  
* **OpenShift Sandboxed Containers** and containerd/CRI‑O runtimes already support this via operators.

**Deployment notes**

1. **Each Dagger pod = separate VM** → plan for +100‑120 MiB RAM and ~15 % more CPU per pod.  
2. Example manifest:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: dagger
   spec:
     runtimeClassName: kata
     containers:
       - name: dagger
         image: ghcr.io/dagger/engine:latest
         securityContext:
           privileged: true
           capabilities:
             add: ["ALL"]
   ```

3. Network stack is transparent (virtio‑net) → sidecars/services communicate as usual.  
4. **CI Example:** Puzzle AG migrated from DinD to Dagger+Kata and removed their recurring disk‑cleanup incidents.

## Migration Template (Ready for Slides)

| Phase | Target Window | Key Tasks |
|-------|---------------|-----------|
| **Week 0‑4** | Immediate | Create node pool, migrate tenants, run Kata PoC |
| **Month 2** | Mid‑term | Measure performance (`kubectl top`), prepare Helm values for customers |
| **Month 6** | Longer | Launch **“No Dagger”** initiative (Tekton + Buildah or Sysbox/rootless BuildKit) |

## Extra Questions

* **“Does GKE Autopilot allow required privileges?”** – No, unless a certified partner (takes time and effort).  
* **“Will Dagger work inside Kata?”** – Yes, confirmed in community issues and CI blog posts.  
* **“Is network communication transparent k8s <-> kata ?”** – Yes, with ~0.2–0.5 ms overhead. Service Mesh (Istio) works; may need `iptables=false` in KataConfig.  
* **“How to scale Dagger with Kata?”** – Use standard HPA/VPA. Plan RAM/CPU overhead. For burst workloads, use a dedicated *kata‑only* node pool with pinned CPUs.


## Other Sandbox Alternatives

**(See full version in Compatibility Matrix doc)**

| Technology | Isolation Model | Dagger Support | Pros | Cons |
|------------|-----------------|----------------|------|------|
| **gVisor** | user‑space syscall trap | *Partial* (BuildKit limited) | ✅ No VMs, fast start | −20‑100 % perf hit, no eBPF/overlayfs; many syscall gaps |
| **Sysbox** (Nestybox) | kernel extensions, rootless | experimental | ✅ Rootless docker‑in‑docker, no VM | community only; no official RPM/DEB for clouds |
| **Firecracker / VM‑Pods** | micro‑VM | BuildKit ok | ✅ AWS native, no root/hostPath | AWS‑only (Fargate); preview in AKS; harder on‑prem |



# Proposed Solutions - Kata - Action List

|  | SaaS (Our GKE Cloud) | On‑Prem (Client's Cluster) |
|---|---|---|
| **Quick fix (<3 months)** | ➜ **Dedicated node‑pool in _Standard_ GKE** with taint `dagger=true` → allow `privileged`, `hostPath`, root. Use **one cluster per customer** for isolation.<br>(Autopilot is off the table – it blocks `privileged`/`hostPath`) | ➜ **Use `kata` RuntimeClass.** Dagger runs “docker‑in‑docker” inside a micro‑VM; the host stays clean. Kata supports **vanilla K8s, OpenShift, EKS Anywhere, AKS preview**, etc. |
| **Risks** | Still running root containers; need per‑tenant cluster isolation | +10–15 % CPU / +100 MiB RAM per pod; need to install Kata |
| **Mid‑term plan (3–9 months)** | 1️⃣ Migrate to **rootless BuildKit** or **Sysbox** (if LLB cache loss is acceptable).<br>2️⃣ Drop `ALL` capabilities, reduce to `NET_ADMIN`, `SYS_ADMIN`. | Stick with Kata/Firecracker; optionally explore **KubeVirt pod‑VMs** for max isolation |
| **Long‑term** | Ditch Dagger completely; replace with Tekton/Buildah or a custom runner | Same; or keep Kata+BuildKit as sandbox fallback |


## 1. Why GKE Autopilot **won’t work right now**

* **Autopilot blocks** `hostPath` and `privileged` for all but certified “partner workloads.”  
* Becoming a partner takes **3–6 months** and lots of vendor back‑and‑forth.  
* Even if whitelisted, you can’t manage the node OS → debugging cache or kernel tweaks becomes painful.

**Conclusion:** the fastest secure path for now is **Standard GKE** with:

- dedicated node pool (`dagger=true`)
- `PodSecurityAdmission: privileged`
- NetworkPolicy isolation

## 2. Kata Containers as a "Wrapper" for Dagger (On‑Prem + SaaS SRE Layer)

**What it gives**

* Runs containers in **micro‑VMs** → full kernel isolation; root escapes are blocked.  
* Supports `--privileged`, `docker-socket`, and `ALL` capabilities **inside** the VM.  
* Just declare a `RuntimeClass: kata` — no change to your main k8s stack.  
* **OpenShift Sandboxed Containers** and containerd/CRI‑O runtimes already support this via operators.

**Deployment notes**

1. **Each Dagger pod = separate VM** → plan for +100‑120 MiB RAM and ~15 % more CPU per pod.  
2. Example manifest:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: dagger
   spec:
     runtimeClassName: kata
     containers:
       - name: dagger
         image: ghcr.io/dagger/engine:latest
         securityContext:
           privileged: true
           capabilities:
             add: ["ALL"]
   ```

3. Network stack is transparent (virtio‑net) → sidecars/services communicate as usual.  
4. **CI Example:** Puzzle AG migrated from DinD to Dagger+Kata and removed their recurring disk‑cleanup incidents.

## 4. Migration Template (Ready for Slides)

| Phase | Target Window | Key Tasks |
|-------|---------------|-----------|
| **Week 0‑4** | Immediate | Create node pool, migrate tenants, run Kata PoC |
| **Month 2** | Mid‑term | Measure performance (`kubectl top`), prepare Helm values for customers |
| **Month 6** | Longer | Launch **“No Dagger”** initiative (Tekton + Buildah or Sysbox/rootless BuildKit) |

## 5. Extra Questions

* **“Does GKE Autopilot allow required privileges?”** – No, unless a certified partner (takes time and effort).  
* **“Will Dagger work inside Kata?”** – Yes, confirmed in community issues and CI blog posts.  
* **“Is network communication transparent k8s <-> kata ?”** – Yes, with ~0.2–0.5 ms overhead. Service Mesh (Istio) works; may need `iptables=false` in KataConfig.  
* **“How to scale Dagger with Kata?”** – Use standard HPA/VPA. Plan RAM/CPU overhead. For burst workloads, use a dedicated *kata‑only* node pool with pinned CPUs.


## 6. Other Sandbox Alternatives

**(See full version in Compatibility Matrix doc)**

| Technology | Isolation Model | Dagger Support | Pros | Cons |
|------------|-----------------|----------------|------|------|
| **gVisor** | user‑space syscall trap | *Partial* (BuildKit limited) | ✅ No VMs, fast start | −20‑100 % perf hit, no eBPF/overlayfs; many syscall gaps |
| **Sysbox** (Nestybox) | kernel extensions, rootless | experimental | ✅ Rootless docker‑in‑docker, no VM | community only; no official RPM/DEB for clouds |
| **Firecracker / VM‑Pods** | micro‑VM | BuildKit ok | ✅ AWS native, no root/hostPath | AWS‑only (Fargate); preview in AKS; harder on‑prem |

# Dagger in Kata Containers: Cloud Marketplace Compatibility

## Brief Summary

Packaging **Dagger in a Kata container** is **technically supported** across **AWS, Azure, and GCP**, **but only with proper setup**:

- **Can ship it as part of Runner** (Helm chart, Terraform module, or Marketplace offer).
- **Kata support varies by platform**: Azure supports it via confidential containers, AWS via Firecracker/AMI customization, and GCP only in **Standard** (not Autopilot) mode.
- We must **guide users to create a Kata-enabled node pool** or package that setup.
- GKE Autopilot is **incompatible** with Kata containers.


## Kata + Dagger Compatibility Matrix

| Platform      | Managed K8s Flavor     | Kata Support | Notes                                                                 |
|---------------|------------------------|--------------|-----------------------------------------------------------------------|
| **AWS**       | EKS Standard           | ++       | Use Firecracker-based AMIs or Bottlerocket with Kata runtime         |
|               | EKS Fargate            | -        | No custom runtime support                                             |
|               | AWS Marketplace App    | +      | Needs custom AMI / instructions for Kata-enabled nodes                |
| **Azure**     | AKS Standard           | ++       | Supported via Confidential Containers + DCv3/ECv3 SKUs                |
|               | Azure Marketplace App  | +      | Must guide user to enable Kata runtime & confidential VM SKUs        |
| **GCP**       | GKE Standard           | +      | Manual setup of node pool + runtime                                   |
|               | GKE Autopilot          | -        | Does not support custom runtimes                                     |
|               | GCP Marketplace App    | +      | Only works with Standard mode + setup guide                          |

> **Legend**: `++` - full support / `+` supported with extra setup / `-` no supported


| Strategy                                                                 | Isolation Strength                                                                                                                                                          | Ease of Implementation                                                                                                                                                              | Performance Impact                                                                                                  | Applicable Environments                                                                                                                                         |
|--------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Status Quo: Privileged in Multi-Tenant Cluster (no isolation)           | **Low**. Dagger runner runs with full node access on shared nodes – high risk of cross-tenant impact if compromised.                                                           |**Easy(if allowed)** Not possible on Autopilot. On standard K8s, just run it with privileged: true. Requires strong trust.                                                            | **None.** Native performance (no sandbox overhead).                                                                      | SaaS (multi-tenant) – Not allowed on Autopilot; **On-Prem** – possible if admin permits. **Not recommended due to risk**.                                       |
| Single-Tenant Cluster per Tenant (Standard GKE or Autopilot)            | **High (Tenant).** Tenants isolated at cluster level; no cross-tenant risk. Within cluster, Dagger still full access to nodes.                                                  | **Moderate**. Automation needed to provision many clusters. Autopilot still blocks privilege (needs workaround), Standard allows it. Overhead in cost and ops for many clusters.         | **Low.** Native performance. Dagger can run privileged.                                                                  | SaaS – feasible for high-value or few tenants; costly for many tenants. **On-Prem** – yes, if each customer deploys their own cluster (common).               |
| Dedicated Node Pool (Tainted Nodes) in Shared Cluster                   | **Medium**. Limits blast radius to specific nodes. Other tenants’ workloads scheduled elsewhere. Node compromise isolated.                                                      |**Easy (Standard K8s)** Define a node pool, add taint, schedule Dagger engine there. Not available in Autopilot.                                                                       | **Moderate** to Low. No virtualization but overhead to isolate Dagger on those nodes (Performance/cost tradeoff).         | SaaS – in standard multi-tenant clusters; not in Autopilot. **On-Prem** – yes, if cluster is shared between services.                                           |
| gVisor Sandbox (runtimeClass)                                           | **High** (Kernel). Strongly isolates container from host kernel. Still shares node, but escape is very hard.                                                                   |**Moderate**. Enabled by setting runtime class and adjusting security policy to allow required caps. Autopilot supports it out-of-box; standard GKE requires node image with gVisor support. |**Moderate** Some syscall and network overhead (user-space handling). Typically lower perf vs. host; slight CPU cost.  | SaaS – Yes, on Autopilot (primary way). Also on any GKE/EKS with gVisor. **On-Prem** – possible (gVisor can be installed with `Containerd`).                     |
| Kata Containers (KVM per pod)                                           | **Very High**. VM-level isolation for each Dagger pod. Strong boundary – like separate VM.                                                                                      |**Complex** Requires Kata runtime on nodes (install via `daemonset` or OpenShift operator). Needs nested or bare-metal virtualization support. Configure runtimeClass and ensure nodes support it. | **Low-Moderate**. Near-native performance for code execution; memory overhead in pods; VM startup latency.               | SaaS – Not on Autopilot. On self-managed K8s if nodes support it (e.g. GKE on bare metal, GKE Standard on certain machines). **On-Prem** – Yes (e.g., OpenShift Sandboxed Containers). |
| KubeVirt VM Instances (Dagger in VM Pod)                               | **Very High**. Full VM isolation within K8s. Also can enforce network policies to limit access.                                                                                 | **High Complexity.** Deploy **KubeVirt** operator (requires cluster admin). Manage VM images, cloud-init, etc. CI pipeline must coordinate VM usage (as Puzzle did).                     | **Low-Moderate.** Much like normal machine running Dagger; performance varies (due to nested startup, scheduling of VMs). | SaaS – Unlikely (too heavy, needs cluster admin). **On-Prem** – Yes, if willing to run virtualization in-cluster (OpenShift CNV or similar). Great when CI team lacks cluster root but can use KubeVirt. |
| Separate Build Cluster (shared or per tenant)                          | **High**. If per-tenant cluster: equivalent to single-tenant (strong). If one shared CI cluster separate from prod: isolates CI risks away from prod clusters.                | **Moderate.** Need infrastructure to spin up/manage extra clusters. But no special tech inside cluster. Possibly standard K8s with restricted Dagger allowed for CI.                     | **Low** Dagger runs natively on nodes.                                                                                   | SaaS – possibly (a dedicated cluster for all CI, or one per customer group). **On-Prem** – yes, often each install is separate anyway.                         |
| External VM per Job (no K8s)                                            | **Very High**. Each job billed in its own VM (no shared host). Complete isolation.                                                                                              | **High (outside K8s)**. Requires orchestration outside Kubernetes to provision **VMs** on-demand (cloud API or VMware, etc.). Integration with CI needed.                                |**Medium-High** VM startup time + possible performance hit versus in-cluster.                                           | SaaS – perhaps for extremely untrusted case (like a premium isolated runner service). **On-Prem** – possible if customers manage VMs; not Kubernetes-native though. |
