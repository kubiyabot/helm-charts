# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.9.x   | :white_check_mark: |
| < 0.9.0 | :x:                |

## Reporting a Vulnerability

The Kubiya team takes security issues seriously. We appreciate your efforts to responsibly disclose your findings.

### How to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by emailing:

**security@kubiya.ai**

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

### What to Include

Please include the following information in your report:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### Helm Chart Specific Concerns

When reporting vulnerabilities specific to our Helm charts, please also include:

- The chart name and version affected
- Kubernetes version and distribution being used
- Any custom values or configurations that may be relevant
- Impact on deployed workloads and cluster security

### What to Expect

- We will acknowledge receipt of your vulnerability report
- We will send you a more detailed response indicating next steps
- We will work to validate and reproduce the issue
- We will keep you informed of our progress towards a fix
- We will notify you when the vulnerability is fixed

### Disclosure Policy

- We will coordinate with you on the timing of public disclosure
- We prefer to fully disclose vulnerabilities after a fix is available
- We will credit you in our security advisories (unless you prefer to remain anonymous)

## Security Best Practices

When using Kubiya Helm charts:

1. **Keep Charts Updated**: Regularly update to the latest chart versions
2. **Review Values**: Carefully review and customize default values for your environment
3. **Secret Management**: Use Kubernetes secrets or external secret managers for sensitive data
4. **RBAC Configuration**: Apply the principle of least privilege in service account permissions
5. **Network Policies**: Implement network policies to restrict pod-to-pod communication
6. **Image Security**: Scan container images for vulnerabilities regularly
7. **Resource Limits**: Set appropriate resource requests and limits
8. **Security Contexts**: Configure security contexts to run containers as non-root users

## Security Updates

Security updates will be released as new chart versions. Please monitor:

- GitHub Security Advisories for this repository
- The [CHANGELOG.md](CHANGELOG.md) for security-related updates
- Our [Artifact Hub](https://artifacthub.io/packages/helm/kubiya-helm-charts/kubiya-runner) page

## Dependencies

Our charts depend on various third-party components. We regularly monitor and update:

- Base container images
- Helm chart dependencies (dagger-helm, kube-state-metrics, alloy)
- Kubernetes API versions

## Additional Resources

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Helm Security Documentation](https://helm.sh/docs/topics/provenance/)
- [CNCF Security TAG](https://github.com/cncf/tag-security)
