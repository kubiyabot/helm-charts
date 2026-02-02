# Neko Helm Chart

This chart deploys the **Neko** browser runtime. It is designed to work primarily within the `browser-agent` umbrella chart but can be used standalone if provided with an external TURN server.

For the full solution architecture (including STUNner gateway), refer to the [Browser Agent Chart](../browser-agent/README.md).

## Overview

Neko runs a full Linux desktop environment with a browser (Firefox/Chrome) inside a Docker container and streams the display via WebRTC.

## Configuration for WebRTC

To function correctly behind NATs and Ingresses, Neko requires careful WebRTC ICE configuration. This chart supports a "Split TURN" configuration to handle Kubernetes networking nuances (specifically UDP hairpinning).

### TURN Configuration

| Parameter | Description | Recommended Value |
| :--- | :--- | :--- |
| `turn.frontendUrl` | The TURN URL sent to the **Client** (Browser). Must be reachable from the public internet. | `turn:<PUBLIC-IP>:3478` |
| `turn.backendUrl` | The TURN URL used by the **Neko Pod**. Must be reachable from inside the cluster. | `turn:<INTERNAL-DNS>:3478` |
| `turn.secretName` | K8s Secret containing `TURN_USERNAME` and `TURN_PASSWORD`. | `neko-secrets` |

### UDP Mux

*   **Port:** `59000` (Default)
*   **Purpose:** Neko uses a single UDP port range for all WebRTC media to simplify firewall/gateway rules.
*   **Configuration:** Handled automatically via `NEKO_WEBRTC_UDPMUX` env var.

## Deployment

### Standalone (Development)
If deploying without the `browser-agent` wrapper, you must ensure:
1.  Ingress Controller is available.
2.  A TURN server is available (or public STUN servers if no symmetric NAT).
3.  Secrets are created manually.

```bash
helm install neko ./charts/neko \
  --set turn.frontendUrl="turn:your-turn.com:3478" \
  --set turn.backendUrl="turn:your-turn.com:3478"
```

## Values Reference

| Key | Description | Default |
| :--- | :--- | :--- |
| `image.repository` | Neko image repository | `m1k1o/neko` |
| `image.tag` | Neko image tag | `firefox` |
| `turn.frontendUrl` | Public-facing TURN URL | `""` |
| `turn.backendUrl` | Internal-facing TURN URL | `""` |
| `pdb.enabled` | Enable Pod Disruption Budget | `false` |
| `resources` | CPU/Memory requests/limits | `{}` |
