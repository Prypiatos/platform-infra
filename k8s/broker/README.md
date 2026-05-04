# HiveMQ broker manifests

This folder contains the Kubernetes manifests for deploying the HiveMQ MQTT
broker with Argo CD.

Argo CD watches the `k8s/` directory, so once these files are committed and
pushed, Argo CD can sync them to the cluster automatically. No manual
`kubectl apply` is needed in the normal GitOps workflow.

## What each file does

- `namespace.yaml` creates the `mqtt` namespace for the broker resources.
- `pvc.yaml` creates persistent storage for the HiveMQ data and log directories
  used by the existing compose setup.
- `deployment.yaml` runs one `hivemq` pod using the same image as the current
  broker compose file: `hivemq/hivemq-ce:latest`.
- `service.yaml` exposes the broker internally inside the cluster as a
  `ClusterIP` Service.
- `service-external.yaml` exposes only MQTT externally through a `NodePort`
  Service so devices outside Kubernetes can connect without exposing the web UI.
- `kustomization.yaml` lets Argo CD or `kubectl kustomize` deploy the whole
  folder as one unit.

## Ports included

The existing `broker/docker-compose.yml` exposes only these HiveMQ ports:

- `1883/TCP` for MQTT
- `8080/TCP` for the HiveMQ web UI

Ports such as `8883`, `8000`, and `9001` are intentionally not included here,
because the current broker setup does not expose them.

## Persistent storage

The compose setup mounts these two directories for HiveMQ:

- `/opt/hivemq/data`
- `/opt/hivemq/log`

Only those two paths get PVCs in Kubernetes, because they are the only broker
paths currently used by the existing config.

## Internal MQTT address

Inside Kubernetes, other applications should connect to the broker using:

```text
hivemq.mqtt.svc.cluster.local:1883
```

## External MQTT access

External devices should connect to:

```text
47.131.156.141:31883
```

That is:

- the control-plane Elastic IP: `47.131.156.141`
- the MQTT NodePort: `31883`

The external Service uses `externalTrafficPolicy: Cluster`, which is important
for this AWS setup because the Elastic IP is attached to the control-plane EC2
instance, while the HiveMQ pod may run on a worker node. Cluster mode lets
Kubernetes forward the NodePort traffic to the correct node automatically.

## How Argo CD deploys this

If your Argo CD Application points to `k8s/` or directly to `k8s/broker`,
Argo CD reads the `kustomization.yaml` file and applies the namespace, PVCs,
Deployment, and Services automatically.

## How to check the deployment

After Argo CD syncs, these commands are useful:

```bash
kubectl get pods -n mqtt
kubectl get svc -n mqtt
kubectl get pvc -n mqtt
```

To inspect the broker logs:

```bash
kubectl logs -n mqtt deploy/hivemq
```

## How to expose it externally later

This repository now includes an external MQTT `NodePort` Service already.
For it to work on AWS, add an inbound rule to the EC2 security group used by
the k3s nodes:

- Protocol: `TCP`
- Port: `31883`
- Source: the device IP range you want to allow

For quick testing you can use `0.0.0.0/0`, but it is better to restrict this
to known client networks if possible.

You do not need to expose the HiveMQ web UI externally unless you specifically
want it. That is why the external Service publishes only MQTT and not port `8080`.

## Current external access setup

If the AWS security-group rule for port `31883` uses:

```text
0.0.0.0/0
```

then any external IPv4 client can try to connect to the broker at:

```text
47.131.156.141:31883
```

This is useful for testing ESP32 devices or other external publishers from
different networks without updating the AWS rule every time their public IP
changes.

## Important security note

Allowing `0.0.0.0/0` means the broker port is reachable from anywhere on the
public internet over IPv4.

That does not automatically mean every client can publish successfully if the
broker later requires authentication, but it does mean anyone can attempt to
connect.

For a safer production-style setup later, tighten one or more of these:

1. Restrict the AWS security-group source CIDR.
2. Add MQTT username/password authentication in HiveMQ.
3. Add TLS for encrypted MQTT connections.
