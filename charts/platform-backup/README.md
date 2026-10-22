# platform-backup Helm Chart

Schedules a backup of **one** data store to S3-compatible storage, as a Kubernetes
`CronJob` running the images of [platform-backup](https://github.com/quyendv/platform-backup).
One release is one backup: install the chart once per database.

## Features

- ✅ **PostgreSQL**, **MongoDB**, **Redis** and **SQLite**, one image per engine
- ✅ The image's environment contract as values: prefix, retention, read-back verification
- ✅ S3 and data store credentials from **existing Secrets** or the **External Secrets Operator**
- ✅ **File stores** (SQLite): mounts the application's volume and runs on its node
- ✅ Fail-fast validation and a **values schema**: a missing schedule, prefix or retention, or two sources for one Secret, fail at install time

## Prerequisites

- Kubernetes 1.27+ (`CronJob.spec.timeZone`)
- Helm 3.14+ or Helm 4
- For `externalSecret`: the [External Secrets Operator](https://external-secrets.io), serving `external-secrets.io/v1`

## Quick Start

```bash
helm repo add quyendv https://quyendv.github.io/helm-charts
helm repo update

kubectl create secret generic backup-s3 \
  --from-literal=AWS_ACCESS_KEY_ID=xxx --from-literal=AWS_SECRET_ACCESS_KEY=yyy \
  --from-literal=AWS_ENDPOINT_URL_S3=https://minio.example.com --from-literal=AWS_REGION=us-east-1 \
  --from-literal=S3_BUCKET=my-bucket
kubectl create secret generic app-postgresql-credentials \
  --from-literal=POSTGRES_USER=backup --from-literal=POSTGRES_PASSWORD=secret

helm install app-postgresql-backup quyendv/platform-backup \
  --set engine=postgresql --set image.variant=pg17 \
  --set schedule="0 2 * * *" \
  --set s3.prefix=backups/app/postgresql --set s3.keepRemote=30 \
  --set s3.existingSecret=backup-s3 \
  --set target.existingSecret=app-postgresql-credentials \
  --set env.POSTGRES_HOST=app-postgresql --set env.POSTGRES_DB=app

# Run one backup now
kubectl create job --from=cronjob/app-postgresql-backup app-postgresql-backup-manual
```

`schedule`, `s3.prefix`, `s3.keepRemote` and a source for the S3 Secret are required. The
chart has no defaults for them because there is no safe guess: a wrong retention deletes
backups.

## How it works

### Image

The image is `<image.registry>/<engine>:<image.tag>[-<image.variant>]`. `image.tag`
defaults to the chart's `appVersion`. Pick the variant that matches the server:

| `engine`     | `image.variant`             | Example image                                            |
| ------------ | --------------------------- | -------------------------------------------------------- |
| `postgresql` | `pg14`, `pg15`, `pg16`, `pg17` | `ghcr.io/quyendv/platform-backup/postgresql:0.6.0-pg17` |
| `mongodb`    | *(empty)*                   | `ghcr.io/quyendv/platform-backup/mongodb:0.6.0`          |
| `redis`      | `redis7`, `redis8`          | `ghcr.io/quyendv/platform-backup/redis:0.6.0-redis8`     |
| `sqlite`     | *(empty)*                   | `ghcr.io/quyendv/platform-backup/sqlite:0.6.0`           |

### Environment

The chart sets these variables and refuses `env` or `extraEnv` entries that repeat them:

| Variable          | From                                  |
| ----------------- | ------------------------------------- |
| `MODE`            | always `backup`                       |
| `S3_PREFIX`       | `s3.prefix`                           |
| `KEEP_LOCAL`      | `keepLocal`                           |
| `KEEP_REMOTE`     | `s3.keepRemote`                       |
| `VERIFY_READBACK` | `verifyReadback`                      |
| `BACKUP_HOST`     | `host`, only when set                 |

Everything else the image reads goes in `env` (a sorted `name: value` map) or `extraEnv`
(full `EnvVar` entries): the store's coordinates (`POSTGRES_HOST`, `POSTGRES_DB`,
`SQLITE_PATH`, ...), `NOTIFY_*`, `MIN_ARTIFACT_BYTES`. Credentials belong in the target
Secret. See each backend's README in the platform-backup repository for its variables.
`VERIFY_READBACK` and `BACKUP_HOST` need image 0.6.0 or later; older images ignore them.

**Retention is a count of runs, not days.** `s3.keepRemote: 0` disables pruning: it keeps
every run, it never means "keep none". The retention window is `keepRemote` × the schedule
interval, so changing the schedule changes how far back the backups reach.

### Secrets

Two Secrets are loaded with `envFrom`, each from exactly one source:

| Secret | Holds | `existingSecret` | `externalSecret.enabled` |
| ------ | ----- | ---------------- | ------------------------ |
| S3 (required) | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_ENDPOINT_URL_S3`, `AWS_REGION`, `S3_BUCKET` | `s3.existingSecret` | creates `<fullname>-s3` |
| Target (optional) | the store's credentials: `POSTGRES_USER`/`POSTGRES_PASSWORD`, `MONGODB_URI`, `REDIS_URL`, ... | `target.existingSecret` | creates `<fullname>-target` |

The S3 ExternalSecret reads one remote key and maps each entry of
`s3.externalSecret.properties` (Secret key → property of the remote key) into the Secret.
Rename a property by changing its value, or leave a key out by setting it to `null` (for
example `AWS_ENDPOINT_URL_S3: null` on AWS itself). With IRSA or an instance role, the S3
Secret can hold `S3_BUCKET` alone.

The target ExternalSecret passes `data`, `dataFrom` and `template` through verbatim, so a
connection string can be assembled from several properties:

```yaml
target:
  externalSecret:
    enabled: true
    secretStoreRef: {name: my-store}
    data:
      - secretKey: password
        remoteRef: {key: secret/app/redis, property: password}
    template:
      engineVersion: v2
      data:
        REDIS_URL: "redis://:{{ .password }}@app-redis-master:6379/0"
```

Both ExternalSecrets use `creationPolicy: Owner` and `deletionPolicy: Retain`: removing the
ExternalSecret keeps the last Secret it delivered.

### Naming: the name must contain "backup"

The CronJob is named after the release fullname, and rendering fails unless that name
contains `backup`. Monitoring commonly selects backup jobs by name, for example
`kube_cronjob_status_last_successful_time{cronjob=~".*backup.*"}`: a backup whose name
does not match is a backup nobody is told about when it stops running.

The fullname follows the usual rule: `fullnameOverride`, else the release name when it
contains the chart name (`nameOverride`, default `platform-backup`), else
`<release>-<chart name>`. So either name the release after the store and set
`fullnameOverride`, or set `nameOverride: backup` and install as `app-postgresql-backup`.
The name may be at most 52 characters, the CronJob limit.

### File stores (SQLite)

SQLite is a file, not a server. With `fileStore.enabled` the job mounts the application's
PersistentVolumeClaim at `fileStore.mountPath` and gets a required `podAffinity` term on
`fileStore.ownerSelector` with `topologyKey: kubernetes.io/hostname`, so it is scheduled on
the node where the volume is attached (a `ReadWriteOnce` volume attaches to one node at a
time). The term is added to any `affinity` you set; your own terms are kept.

The claim is mounted **read-write** by default. The sqlite backend copies with the
application's locks held, which needs a writable mount and root with `CHOWN`,
`DAC_OVERRIDE` and `FOWNER`; a read-only mount makes the copy retry, or fail, while the
application writes. Set `fileStore.readOnly: true` only for stores that never need it. See
[`examples/values-sqlite-example.yaml`](examples/values-sqlite-example.yaml) for the
security context.

### Knowing when a backup fails

Each run is a fresh pod with an `emptyDir` at `/backup`, so a failed run shows up as a
`Failed` Job, and the image's state file does not survive between runs. Leave `NOTIFY_ON`
at `failure`: `change` would fire on every run, since the previous outcome is never known.

### Several stores from one parent chart

The schema accepts a root `enabled` key and `global`, so the chart can be a dependency
several times under different aliases:

```yaml
dependencies:
  - name: platform-backup
    alias: app-postgresql-backup
    version: 0.1.0
    repository: https://quyendv.github.io/helm-charts
    condition: app-postgresql-backup.enabled
  - name: platform-backup
    alias: app-redis-backup
    version: 0.1.0
    repository: https://quyendv.github.io/helm-charts
    condition: app-redis-backup.enabled
```

## Parameters

### Backup parameters

| Name                | Description                                                                                                                                                                 | Value                             |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- |
| `engine`            | Data store to back up: postgresql, mongodb, redis or sqlite. Selects the image                                                                                              | `postgresql`                      |
| `image.registry`    | Registry and path the per-engine images live under                                                                                                                          | `ghcr.io/quyendv/platform-backup` |
| `image.tag`         | Image release tag (empty uses the chart appVersion)                                                                                                                         | `""`                              |
| `image.variant`     | Image variant appended to the tag: pg14..pg17 for postgresql, redis7/redis8 for redis; empty for mongodb and sqlite                                                         | `""`                              |
| `image.pullPolicy`  | Image pull policy                                                                                                                                                           | `IfNotPresent`                    |
| `nameOverride`      | String to partially override the chart name                                                                                                                                 | `""`                              |
| `fullnameOverride`  | String to fully override the release fullname. The resulting name must contain "backup" and be at most 52 characters                                                        | `""`                              |
| `schedule`          | Cron schedule of the backup (REQUIRED)                                                                                                                                      | `""`                              |
| `timeZone`          | Time zone the schedule is read in                                                                                                                                           | `UTC`                             |
| `suspend`           | Suspend the schedule (Jobs already started keep running)                                                                                                                    | `false`                           |
| `concurrencyPolicy` | What to do when a run is still going at the next tick (Forbid, Allow or Replace)                                                                                            | `Forbid`                          |
| `keepLocal`         | Runs kept in the scratch directory (KEEP_LOCAL); 0 disables pruning                                                                                                         | `1`                               |
| `verifyReadback`    | Download the uploaded artifact again and check its checksum (VERIFY_READBACK)                                                                                               | `false`                           |
| `host`              | Where the backup runs, such as a cluster name (BACKUP_HOST): recorded in each run's _COMPLETE marker, its state file and notifications. Empty leaves the container hostname | `""`                              |
| `env`               | Extra environment variables as a name: value map, rendered sorted (e.g. SQLITE_PATH, NOTIFY_ON)                                                                             | `{}`                              |
| `extraEnv`          | Extra environment variables as full EnvVar entries (valueFrom etc.), rendered after env                                                                                     | `[]`                              |

### Object storage parameters

| Name                                    | Description                                                                                           | Value                                          |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| `s3.prefix`                             | Key prefix inside the bucket (S3_PREFIX, REQUIRED)                                                    | `""`                                           |
| `s3.keepRemote`                         | Runs kept in S3 (KEEP_REMOTE, REQUIRED); 0 disables pruning, it never means keep none                 | `nil`                                          |
| `s3.existingSecret`                     | Existing Secret with the AWS_* and S3_BUCKET keys, loaded with envFrom                                | `""`                                           |
| `s3.externalSecret.enabled`             | Create the S3 Secret from an ExternalSecret                                                           | `false`                                        |
| `s3.externalSecret.refreshInterval`     | How often the operator refreshes the Secret                                                           | `1h`                                           |
| `s3.externalSecret.secretStoreRef.kind` | Kind of the secret store (ClusterSecretStore or SecretStore)                                          | `ClusterSecretStore`                           |
| `s3.externalSecret.secretStoreRef.name` | Name of the secret store                                                                              | `""`                                           |
| `s3.externalSecret.remoteKey`           | Key in the secret store that holds the S3 settings                                                    | `""`                                           |
| `s3.externalSecret.properties`          | Secret key (environment variable) -> property of the remote key. Set an entry to null to leave it out | `each S3 key to the property of the same name` |

### Target parameters

| Name                                        | Description                                                                 | Value                |
| ------------------------------------------- | --------------------------------------------------------------------------- | -------------------- |
| `target.existingSecret`                     | Existing Secret with the data store's credentials                           | `""`                 |
| `target.externalSecret.enabled`             | Create the target Secret from an ExternalSecret                             | `false`              |
| `target.externalSecret.refreshInterval`     | How often the operator refreshes the Secret                                 | `1h`                 |
| `target.externalSecret.secretStoreRef.kind` | Kind of the secret store (ClusterSecretStore or SecretStore)                | `ClusterSecretStore` |
| `target.externalSecret.secretStoreRef.name` | Name of the secret store                                                    | `""`                 |
| `target.externalSecret.data`                | ExternalSecret spec.data, passed through verbatim                           | `[]`                 |
| `target.externalSecret.dataFrom`            | ExternalSecret spec.dataFrom, passed through verbatim                       | `[]`                 |
| `target.externalSecret.template`            | ExternalSecret spec.target.template, passed through verbatim when non-empty | `{}`                 |

### File store parameters

| Name                      | Description                                                                                          | Value   |
| ------------------------- | ---------------------------------------------------------------------------------------------------- | ------- |
| `fileStore.enabled`       | Mount the data store's PersistentVolumeClaim and run next to the pod that owns it                    | `false` |
| `fileStore.claimName`     | PersistentVolumeClaim holding the data store (required when enabled)                                 | `""`    |
| `fileStore.mountPath`     | Where the claim is mounted in the container                                                          | `/data` |
| `fileStore.readOnly`      | Mount the claim read-only. Leave false for sqlite, which must take part in the application's locking | `false` |
| `fileStore.ownerSelector` | matchLabels of the pod that owns the claim (required when enabled)                                   | `{}`    |

### Job parameters

| Name                             | Description                                                                | Value   |
| -------------------------------- | -------------------------------------------------------------------------- | ------- |
| `scratch.sizeLimit`              | Size limit of the emptyDir mounted at /backup, where each run is assembled | `10Gi`  |
| `job.backoffLimit`               | Retries of a failed run before the Job fails                               | `2`     |
| `job.activeDeadlineSeconds`      | Seconds a run may take before it is killed                                 | `21600` |
| `job.ttlSecondsAfterFinished`    | Seconds a finished Job is kept                                             | `86400` |
| `job.successfulJobsHistoryLimit` | Successful Jobs kept by the CronJob                                        | `3`     |
| `job.failedJobsHistoryLimit`     | Failed Jobs kept by the CronJob                                            | `1`     |

### Pod parameters

| Name                           | Description                                                                                      | Value   |
| ------------------------------ | ------------------------------------------------------------------------------------------------ | ------- |
| `resources`                    | Container resource requests and limits                                                           | `{}`    |
| `podLabels`                    | Extra labels for the Jobs and their pods                                                         | `{}`    |
| `podAnnotations`               | Annotations for the pods                                                                         | `{}`    |
| `commonLabels`                 | Labels added to every object                                                                     | `{}`    |
| `imagePullSecrets`             | Names of Secrets used to pull the image                                                          | `[]`    |
| `serviceAccountName`           | ServiceAccount the pods run as (empty uses the namespace default)                                | `""`    |
| `automountServiceAccountToken` | Mount the ServiceAccount token in the pods                                                       | `false` |
| `nodeSelector`                 | Node labels for pod assignment                                                                   | `{}`    |
| `tolerations`                  | Tolerations for pod assignment                                                                   | `[]`    |
| `affinity`                     | Affinity for pod assignment. With fileStore enabled, the owner's podAffinity term is added to it | `{}`    |
| `podSecurityContext`           | Pod security context                                                                             | `{}`    |
| `securityContext`              | Container security context                                                                       | `{}`    |
| `extraVolumes`                 | Extra volumes for the pods                                                                       | `[]`    |
| `extraVolumeMounts`            | Extra volume mounts for the container                                                            | `[]`    |

## Examples

- [`examples/values-postgresql-example.yaml`](examples/values-postgresql-example.yaml): PostgreSQL every four hours, both Secrets from the External Secrets Operator
- [`examples/values-sqlite-example.yaml`](examples/values-sqlite-example.yaml): SQLite on an application's volume
- [`ci/`](ci/): one fixture per engine, rendered and validated in CI

```bash
helm template app-postgresql-backup charts/platform-backup -f charts/platform-backup/examples/values-postgresql-example.yaml
```

## Maintaining the parameter docs

The tables in [Parameters](#parameters) are generated from the `## @param` / `## @section`
annotations in `values.yaml` by
[readme-generator-for-helm](https://github.com/bitnami/readme-generator-for-helm). Do not
edit them by hand: change `values.yaml`, then run `make docs` from the repository root.
Keep `values.schema.json` in step with `values.yaml`.

## License

[MIT License](../../LICENSE)
