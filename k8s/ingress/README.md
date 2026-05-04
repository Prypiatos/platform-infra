# ingress-nginx externalTrafficPolicy override

This folder contains the Kubernetes manifest that makes `ingress-nginx` use:

```yaml
externalTrafficPolicy: Cluster
```

## Why we need this

Our k3s cluster runs on AWS EC2 and the public Elastic IP is attached to the
control-plane instance.

At the same time, the `ingress-nginx` controller pods may run on worker nodes.
That means external traffic can arrive at the control-plane node first, even
when the actual ingress pod that should serve the request is running elsewhere.

Using `externalTrafficPolicy: Cluster` fixes that routing path:

- traffic reaches the Elastic IP on the control-plane EC2 instance
- the Service receives that traffic through its NodePort
- kube-proxy can forward the request to a healthy `ingress-nginx` pod on a worker node

If `externalTrafficPolicy` is set to `Local`, the node that receives the traffic
only sends it to local pod endpoints. In our setup that can break ingress when
the control-plane node does not currently run an `ingress-nginx` pod.

## Manifest

Apply this after `ingress-nginx` is installed:

```bash
kubectl apply -f k8s/ingress/ingress-nginx-controller-service.yaml
```

## Helm equivalent

If you install `ingress-nginx` with Helm later, the matching value is:

```yaml
controller:
  service:
    externalTrafficPolicy: Cluster
```
