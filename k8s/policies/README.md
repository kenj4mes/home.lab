# Kubernetes Network Policies

Zero-trust network security with Kubernetes Network Policies.

## Files

| File | Description |
|------|-------------|
| `default-deny-all.yaml` | Default deny ingress/egress for all namespaces |
| `allow-monitoring.yaml` | Allow Prometheus to scrape all namespaces |
| `allow-database.yaml` | Controlled database access from specific services |

## Philosophy

These policies implement a **zero-trust** network model:

1. **Default Deny**: Block all traffic by default
2. **Explicit Allow**: Whitelist only necessary connections
3. **Least Privilege**: Minimal access for each service

## Application

```bash
# Apply policies
kubectl apply -f .

# Verify policies
kubectl get networkpolicies -A
```

## Policy Patterns

### Default Deny (Applied to All Namespaces)
```yaml
spec:
  podSelector: {}  # Matches all pods
  policyTypes:
    - Ingress
    - Egress
```

### Allow Specific Traffic
```yaml
spec:
  podSelector:
    matchLabels:
      app: my-app
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: trusted-namespace
      ports:
        - port: 8080
```

## Testing

```bash
# Test connectivity from one pod to another
kubectl exec -it test-pod -- curl http://target-service:8080

# Check if blocked (should timeout)
kubectl exec -it blocked-pod -- curl --connect-timeout 5 http://restricted-service:8080
```

## CNI Requirements

These policies require a CNI that supports NetworkPolicy:
- ✅ Cilium (recommended)
- ✅ Calico
- ✅ Weave Net
- ❌ Flannel (no NetworkPolicy support)

## Related

- [Cilium CNI](../infrastructure/cilium.yaml)
- [Security Documentation](../../docs/SECURITY.md)
