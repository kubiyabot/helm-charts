# Call With Shaked Presentation

- [Topics](#topics)
- [Dagger](#dagger)
  - [Why Dagger?](#why-dagger)
  - [In essence](#in-essence)
  - [Extra input from Dima](#extra-input-from-dima)
  - [Data isolation](#data-isolation)
    - [In theory: No Need for a Privileged Docker Daemon](#in-theory-no-need-for-a-privileged-docker-daemon)
  - [More details](#more-details)
    - [Cache Invalidation](#cache-invalidation)
    - [Cache Consistency](#cache-consistency)
    - [Overhead of Distributed Cache Management](#overhead-of-distributed-cache-management)
    - [Synchronization Latency](#synchronization-latency)
    - [Storage Resource Consumption](#storage-resource-consumption)
    - [Difficulty in Cache Eviction](#difficulty-in-cache-eviction)
    - [Performance Penalties](#performance-penalties)
- [vCluster](#vcluster)
  - [Why vCluster?](#why-vcluster)
  - [Problems](#problems)

# Topics
- Dagger
- vCluster

# Dagger

## Why Dagger?

Assumption: expected to be better than simple Docker-in-Docker for performance (due to superior caching, data isolation).

Caching - Problems with horizontal scalability ([GitHub Issue #6486](https://github.com/dagger/dagger/issues/6486)) when there is no shared cache (NFS, Redis, S3, Cloud Cache, etc.) - the reason why vendor introduced external cloud cache (which is far from perfect according to community feedback).

## In essence

Without external caching: In both `DaemonSet` and `StatefulSet` configurations, Dagger does not sync cache between nodes. Each node will have its own independent cache, and tasks may need to be re-executed if they require cached data that was previously generated on another node.

External/cloud cache - not suitable for enterprise/security/on-premises/self-contained solutions. Also, external transfers are neither reliable nor performant (sync transfers overhead, disk usage, compute resource consumption, eviction and invalidation issues, etc).

## Extra input from Dima

- We deploy a separate registry into runner's namespace via `tool-manager`, which acts like a caching registry (solely?)
- Users cannot stop tool execution. Dagger cannot stop execution by API call - meaning users cannot stop executions
- No real time output. Dagger buffers output of execs/ci and only able to return it all at the end of execution
- (?) Apart from main scale reason caching does not work for us as Dagger cannot re-use cached images which differs, for example, from a new build by one nodejs lib  // ---> wrong Dagger must work like this and build this case from cached images
- Production scaling issues: not horizontally: Not really effective Local cache doesn't scale, especially considering our architecture (vCluster/multitenancy on same nodes)
- We have to use our "flow" wrapper to use cached image from our registry

## Data isolation

In Dagger, each container runs isolated tasks, but you don't have to open up a privileged container. This avoids some inherent security risks associated with DinD. But same time we have god mode for Dagger container ATM [provide quotes from k8s manifest]:

### In theory: No Need for a Privileged Docker Daemon

- **Docker-in-Docker**: In DinD, the outer container (the parent) needs to run in privileged mode to allow the inner container (child container) to access the Docker daemon and perform container operations. This can be a security risk because it exposes the Docker socket and gives the inner container elevated permissions, which can lead to privilege escalation or other security issues.

- **Dagger**: Dagger does not require a privileged Docker daemon. Instead, it uses container runtimes like Docker, containerd, or Podman, but it isolates tasks more effectively. Each task in Dagger is run in a separate container that doesn't require elevated privileges to interact with the container runtime. Dagger manages its own isolated environments for tasks, without the need to expose Docker's privileged access.

Yet, we run Dagger in GOD MODE ON

## More details

### Cache Invalidation
- **Problem**: In a horizontally scaled environment, cache invalidation can become a complex issue. Since multiple nodes might be storing cached data, it's difficult to ensure that the cache is updated or invalidated consistently across all nodes when the source data changes.
- **Example**: If a task on one node updates the cache, other nodes might still be using outdated cache, leading to inconsistencies and potentially incorrect results.

### Cache Consistency
- **Problem**: Ensuring cache consistency across nodes is a challenge. Each node might have its own local cache, which could lead to discrepancies in data when tasks are distributed across multiple workers.
- **Example**: If each node is caching intermediate results locally, then the cache might not reflect the most current state of the data, especially if one part of the task is retried or restarted.

### Overhead of Distributed Cache Management
- **Problem**: Managing a distributed cache system (e.g., using an external storage like S3 or Redis) can introduce additional overhead. This involves more complexity in coordinating cache access, updates, and invalidation across multiple machines.
- **Example**: Implementing persistent caching across distributed nodes requires a reliable system for coordinating cache synchronization. This may involve using complex caching strategies or third-party systems like distributed key-value stores, which come with their own set of performance and consistency challenges.

### Synchronization Latency
- **Problem**: There can be latency when synchronizing caches between nodes. When a cache is updated on one node, it might take time for the changes to propagate to other nodes, leading to performance bottlenecks and delays.
- **Example**: In large-scale environments, when multiple nodes are performing jobs that depend on shared cache, the time it takes to synchronize the cache across nodes can affect overall job execution time and lead to performance degradation.

### Storage Resource Consumption
- **Problem**: Storing large caches across multiple nodes can lead to significant storage overhead. Each node might need to store parts of the cache, which can increase resource consumption and complicate scaling decisions.
- **Example**: If each worker node keeps its own local cache of the build artifacts, it could lead to inefficient resource usage, especially when those caches are large and must be synchronized frequently.

### Difficulty in Cache Eviction
- **Problem**: Evicting stale or unused cache entries across nodes becomes more challenging when scaling horizontally. In a distributed environment, it's harder to know which caches are no longer needed, which can result in excessive memory usage and reduced efficiency.
- **Example**: If cache entries are not evicted properly, it could lead to nodes running out of disk space, slowing down the system due to inefficient memory use, or even crashing due to resource exhaustion.

### Performance Penalties
- **Problem**: Horizontal scaling can introduce performance penalties if cache access times are slow due to the complexity of coordinating data between nodes.
- **Example**: When distributed caches are used, fetching data from a central cache storage (e.g., an S3 bucket or Redis) might add latency to job execution. This can negate the benefits of horizontal scaling by introducing additional delays in retrieving cached results.

# vCluster

## Why vCluster?

Dedicated extra isolation layer for Dagger to support multitenancy in our clouds running multiple managed runners environments.

## Problems

- Does not help us to isolate Dagger instances without *isolated mode ON* ([vCluster Docs](https://www.vcluster.com/docs/v0.19/security/isolated-mode))
- Isolated mode puts restriction on workload configuration which can run within cluster - we cannot run Dagger with current `GOD MODE = ON`
- No host data isolation and flat networking by default (vCluster A can access B by its parent's k8s network IPs)
- Doesn't provide full isolation unless extra steps for secure workload configuration done
- Depending on configuration and use case needs extra steps for k8s security config (CNI requirements, RBAC, Network Policy, Resources, etc)
- Resource consumption penalties (`see vcluster-overhead.md`) and scalability issues
- On-premises compatibility and customer requirements issues
- Extra complexity for devs and ops - extra tech to learn, extra layer of maintenance, extra effort for operational arch & executions
- Performance penalties (1-10-100 ms - unknown, but 100% exists)
- Resources management challenge: running 10 customers runners within 15 vClusters on 5 nodes
- Tech/Vendor locks
- Extra point of failure 
- Wider attack surface
