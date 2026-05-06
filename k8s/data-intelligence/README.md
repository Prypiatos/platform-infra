# data-intelligence manifests

This folder contains the first Kubernetes pass for the `data-intelligence`
runtime stack from `data-intelligence/docker-compose.yml`.

Included in this first pass:

- `postgres`
- `influxdb`
- `kafka`
- `mosquitto`
- `api`
- `mlflow`
- `airflow`
- `streaming`
- `ingestion`
- `storage`
- `anomaly`

Notes:

- The custom images are expected to be built and pushed separately. The
  manifests currently reference:
  - `sheharakarunarathna/e2-api:91854711608e98bad8ccf49bb69e3d50acea113`
  - `sheharakarunarathna/e2-airflow:latest`
  - `sheharakarunarathna/e2-streaming:latest`
  - `sheharakarunarathna/e2-ingestion:latest`
  - `sheharakarunarathna/e2-storage:latest`
  - `sheharakarunarathna/e2-anomaly:latest`
- Secret values currently mirror the repo's development defaults so the stack
  can boot. Replace them before any non-demo deployment.
- `mosquitto` gets an explicit config here because the compose file does not
  mount one, and Mosquitto 2.x is safer to run with the listener configured
  intentionally.
- `airflow` is deployed for management parity, but the current upstream image
  still lacks Spark tooling. Its batch DAGs will need an improved image to run
  successfully.
