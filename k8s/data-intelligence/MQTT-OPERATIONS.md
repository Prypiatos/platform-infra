# MQTT Broker Operations

This note describes how to connect to the Mosquitto broker running in the
`data-intelligence` namespace and how to inspect live MQTT traffic from the
server side.

## Preconditions

Run these from the control-plane server:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

The broker deployment and services are:

- internal service: `mosquitto:1883`
- external service: `mosquitto-external:1883`
- namespace: `data-intelligence`

## Find The Broker Pod

```bash
sudo -E kubectl get pods -n data-intelligence -l app=mosquitto
```

## Open A Shell Inside The Broker Pod

```bash
sudo -E kubectl exec -it -n data-intelligence deploy/mosquitto -- sh
```

If `deploy/mosquitto` does not work for any reason, use the pod name directly:

```bash
sudo -E kubectl exec -it -n data-intelligence <mosquitto-pod-name> -- sh
```

## Subscribe To All Topics Inside The Broker Pod

Once inside the pod:

```bash
mosquitto_sub -h localhost -p 1883 -t '#' -v
```

This is the most useful command for seeing live traffic flow through the broker.

## Subscribe To A Specific Topic

```bash
mosquitto_sub -h localhost -p 1883 -t 'energy/#' -v
```

Examples:

```bash
mosquitto_sub -h localhost -p 1883 -t 'energy/nodes/+/telemetry' -v
mosquitto_sub -h localhost -p 1883 -t 'energy/nodes/+/health' -v
mosquitto_sub -h localhost -p 1883 -t 'energy/nodes/+/event' -v
mosquitto_sub -h localhost -p 1883 -t 'energy/nodes/+/cmd/#' -v
```

## Publish A Test Message From Inside The Broker Pod

```bash
mosquitto_pub -h localhost -p 1883 -t 'test/hello' -m 'hello from mosquitto pod'
```

You can use this together with `mosquitto_sub` in another shell to confirm the
broker is routing messages.

## Watch Broker Logs From The Server

```bash
sudo -E kubectl logs -n data-intelligence deploy/mosquitto -f
```

This shows broker startup and persistence activity. It is less detailed than
`mosquitto_sub` for message content.

## Watch Ingestion Consume MQTT Messages

```bash
sudo -E kubectl logs -n data-intelligence deploy/ingestion -f
```

Use this when you want to confirm that MQTT messages are not only reaching
Mosquitto, but are also being consumed by the E2 ingestion service.

## Test The External Entry Point

From a machine outside the cluster:

```bash
nc -vz 47.131.156.141 1883
```

If Mosquitto client tools are available:

```bash
mosquitto_pub -h 47.131.156.141 -p 1883 -t 'test/hello' -m 'hello from outside'
mosquitto_sub -h 47.131.156.141 -p 1883 -t '#' -v
```

## Useful Service Checks

```bash
sudo -E kubectl get svc -n data-intelligence
sudo -E kubectl describe svc -n data-intelligence mosquitto
sudo -E kubectl describe svc -n data-intelligence mosquitto-external
```

## Quick End-To-End Check

1. In one shell on the control plane:

```bash
sudo -E kubectl exec -it -n data-intelligence deploy/mosquitto -- \
  mosquitto_sub -h localhost -p 1883 -t '#' -v
```

2. In another shell outside the cluster:

```bash
mosquitto_pub -h 47.131.156.141 -p 1883 -t 'test/hello' -m 'edge test'
```

3. Back on the control plane, confirm the message appears in the subscriber.

## Troubleshooting

If no traffic appears:

```bash
sudo -E kubectl get pods -n data-intelligence
sudo -E kubectl get svc -n data-intelligence
sudo -E kubectl logs -n data-intelligence deploy/mosquitto --tail=100
sudo -E kubectl logs -n data-intelligence deploy/ingestion --tail=100
```

If the external client cannot connect:

```bash
nc -vz 47.131.156.141 1883
sudo -E kubectl get svc -n data-intelligence mosquitto-external
sudo -E kubectl get pods -n kube-system | grep svclb
```
