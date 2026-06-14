# aks-pod-communication-control

Purpose
-------
This repository contains a minimal set of Kubernetes manifests and notes to demonstrate and verify NetworkPolicy (pod/namespace level) enforcement in a cluster (for example AKS). Use these manifests to apply namespaces, pods and a NetworkPolicy, then validate allowed and denied traffic between namespaces.

Prerequisites
-------------
- A Kubernetes cluster reachable from your local `kubectl` (context set).
- The cluster must support NetworkPolicy enforcement (CNI plugin with policy support such as Calico, or AKS with `network_policy = "azure"` as in `main.tf`).
- `kubectl` installed and authenticated.

What’s in this repo
--------------------
- `ns.yaml` — Namespace definitions: `ns-fire` and `ns-nginx`.
- `niginx.yaml` — A single `nginx` Pod in `ns-nginx` (label: `rule: nginxrule`).
- `firefox.yaml` — A `firefox` Pod and a `netshoot` debug Pod in `ns-fire`.
- `ns-fire-block-np.yaml` — A NetworkPolicy in `ns-nginx` that restricts ingress to the nginx pod(s) to traffic from the `ns-nginx` namespace only.
- `main.tf` — Terraform AKS example showing `network_policy = "azure"` (illustrative for AKS environments).

Note: small doc tweak (commit marker 1).

<!-- commit-marker-1 -->

High-level intent
-----------------
The `deny-firefox` NetworkPolicy (in `ns-fire-block-np.yaml`) scopes to pods labeled `rule: nginxrule` in namespace `ns-nginx` and allows ingress only from namespaces labeled `name: nginx`. In effect, pods in `ns-fire` (for example `netshoot-pod`) should be blocked from reaching the `nginx` pod unless they are moved into `ns-nginx` or the policy is adjusted.

Apply the manifests
-------------------
Apply namespaces, pods, and the NetworkPolicy in order:

```bash
kubectl apply -f ns.yaml
kubectl apply -f niginx.yaml
kubectl apply -f firefox.yaml
kubectl apply -f ns-fire-block-np.yaml
```

Quick verification steps
------------------------
1. Confirm pods and namespaces are running:

```bash
kubectl get ns
kubectl get pods -A
```

2. Get the nginx pod IP:

```bash
NGINX_IP=$(kubectl get pod nginx-pod -n ns-nginx -o jsonpath='{.status.podIP}')
echo $NGINX_IP
```

3. From the `netshoot` pod in `ns-fire`, attempt to curl the nginx pod IP:

```bash
kubectl -n ns-fire exec -it netshoot-pod -- bash
# inside the netshoot shell:
curl -v --max-time 5 http://$NGINX_IP:80 || echo "connection failed"
exit
```

Expected result: connection should fail or time out because the NetworkPolicy only permits ingress from the `ns-nginx` namespace.

4. To confirm allowed traffic, run a temporary debug pod in `ns-nginx` and curl the same IP:

```bash
kubectl -n ns-nginx run -it --rm test-netshoot --image=nicolaka/netshoot -- /bin/bash -c "curl -v --max-time 5 http://$NGINX_IP:80"
```

Expected result: the request should succeed (200 or a response from nginx) because this request originates from `ns-nginx`, which the policy allows.

Inspecting the NetworkPolicy
----------------------------
Use these commands to inspect the applied policy and see how it matches pods/namespaces:

```bash
kubectl -n ns-nginx get networkpolicy
kubectl -n ns-nginx describe networkpolicy deny-firefox
kubectl -n ns-nginx get pods --show-labels
kubectl get ns --show-labels
```

