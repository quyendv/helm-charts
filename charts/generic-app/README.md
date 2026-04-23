# Generic Application Helm Chart

A comprehensive, production-ready Helm chart that can be used as a template for deploying various applications to Kubernetes. This chart follows best practices from major open-source projects like Bitnami.

## Features

- ✅ Support for both **Deployment** and **StatefulSet**
- ✅ Flexible **Service** configuration (ClusterIP, NodePort, LoadBalancer)
- ✅ **Ingress** with TLS support
- ✅ **Gateway API** (`HTTPRoute`) and optional cert-manager **Certificate** for TLS secrets used by Gateways
- ✅ **Automatic SSL/TLS certificate** management with cert-manager (Let's Encrypt, CA, Vault)
- ✅ **ConfigMaps** and **Secrets** management
- ✅ **Persistent Volume Claims** (PVC)
- ✅ **ServiceAccount** and **RBAC** configuration
- ✅ **Horizontal Pod Autoscaling** (HPA)
- ✅ **Pod Disruption Budget** (PDB)
- ✅ **Network Policy**
- ✅ **Security Context** configuration
- ✅ **Probes** (Liveness, Readiness, Startup)
- ✅ **Affinity** and **Anti-Affinity** rules
- ✅ **Init containers** and **Sidecars**
- ✅ **Extra volumes** and **volume mounts**
- ✅ **Extra Deploy** - Deploy additional Kubernetes resources with full templating support

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+

## Quick Start

### Add Helm Repository

```bash
helm repo add quyendv https://quyendv.github.io/helm-charts
helm repo update
```

### Install Chart

```bash
# Install with default values
helm install my-app quyendv/generic-app

# Install with custom values
helm install my-app quyendv/generic-app -f my-values.yaml

# Install specific version
helm install my-app quyendv/generic-app --version 1.7.0

# Install with inline values
helm install my-app quyendv/generic-app \
  --set image.repository=nginx \
  --set image.tag=1.25.3 \
  --set service.type=LoadBalancer
```

### Install from Source

```bash
# Clone repository
git clone https://github.com/quyendv/helm-charts.git
cd helm-charts

# Install chart (from repository root)
helm install my-app ./charts/generic-app -f my-values.yaml
```

## Uninstalling the Chart

To uninstall/delete the `my-app` deployment:

```bash
helm uninstall my-app
```

## Configuration

The following table lists the configurable parameters and their default values.

### Global Parameters

| Parameter                 | Description                                  | Default |
| ------------------------- | -------------------------------------------- | ------- |
| `global.imageRegistry`    | Global Docker image registry                 | `""`    |
| `global.imagePullSecrets` | Global Docker registry secret names          | `[]`    |
| `global.storageClass`     | Global StorageClass for Persistent Volume(s) | `""`    |

### Common Parameters

| Parameter           | Description                                | Default |
| ------------------- | ------------------------------------------ | ------- |
| `nameOverride`      | String to partially override the fullname  | `""`    |
| `fullnameOverride`  | String to fully override the fullname      | `""`    |
| `namespaceOverride` | String to override the namespace           | `""`    |
| `commonLabels`      | Labels to add to all deployed objects      | `{}`    |
| `commonAnnotations` | Annotations to add to all deployed objects | `{}`    |

### Application Parameters

| Parameter           | Description                               | Default        |
| ------------------- | ----------------------------------------- | -------------- |
| `replicaCount`      | Number of replicas                        | `1`            |
| `kind`              | Workload kind (Deployment or StatefulSet) | `Deployment`   |
| `image.registry`    | Image registry                            | `docker.io`    |
| `image.repository`  | Image repository                          | `nginx`        |
| `image.tag`         | Image tag                                 | `1.25.3`       |
| `image.pullPolicy`  | Image pull policy                         | `IfNotPresent` |
| `image.pullSecrets` | Image pull secrets                        | `[]`           |

### Environment Variables Parameters

| Parameter                | Description                            | Default |
| ------------------------ | -------------------------------------- | ------- |
| `extraEnvVars`           | Array of extra environment variables   | `[]`    |
| `extraEnvVarsConfigMaps` | List of ConfigMaps to load as env vars | `[]`    |
| `extraEnvVarsSecrets`    | List of Secrets to load as env vars    | `[]`    |

### Service Parameters

| Parameter             | Description             | Default      |
| --------------------- | ----------------------- | ------------ |
| `service.type`        | Kubernetes Service type | `ClusterIP`  |
| `service.ports`       | Service ports           | `{http: 80}` |
| `service.annotations` | Service annotations     | `{}`         |

### Cert-Manager Parameters

| Parameter                   | Description                           | Default         |
| --------------------------- | ------------------------------------- | --------------- |
| `certManager.enabled`       | Enable cert-manager issuer creation   | `false`         |
| `certManager.issuerType`    | Type of issuer (Issuer/ClusterIssuer) | `ClusterIssuer` |
| `certManager.issuerName`    | Name of the issuer                    | `""`            |
| `certManager.acme.enabled`  | Enable ACME issuer (Let's Encrypt)    | `true`          |
| `certManager.acme.server`   | ACME server URL                       | Production      |
| `certManager.acme.email`    | Email for ACME registration           | `""`            |
| `certManager.acme.solvers`  | ACME challenge solvers                | HTTP01 nginx    |
| `certManager.ca.enabled`    | Enable CA issuer                      | `false`         |
| `certManager.ca.secretName` | Secret containing CA certificate      | `""`            |
| `certManager.vault.enabled` | Enable Vault issuer                   | `false`         |
| `certManager.vault.server`  | Vault server URL                      | `""`            |

### Ingress Parameters

| Parameter                  | Description                           | Default     |
| -------------------------- | ------------------------------------- | ----------- |
| `ingress.enabled`          | Enable ingress controller resource    | `false`     |
| `ingress.ingressClassName` | IngressClass name                     | `""`        |
| `ingress.hostname`         | Default host for the ingress resource | `app.local` |
| `ingress.path`             | Default path for the ingress resource | `/`         |
| `ingress.tls`              | Enable TLS configuration              | `false`     |
| `ingress.annotations`      | Ingress annotations                   | `{}`        |

### Gateway API parameters

| Parameter                                  | Description                                                         | Default |
| ------------------------------------------ | ------------------------------------------------------------------- | ------- |
| `gatewayApi.enabled`                       | Create `HTTPRoute` (and optional `Certificate`)                     | `false` |
| `gatewayApi.apiVersion`                    | HTTPRoute API version (empty = `gateway.networking.k8s.io/v1`)     | `""`    |
| `gatewayApi.hostname`                      | Convenience hostname (merged into route/cert hostnames)            | `""`    |
| `gatewayApi.httpRoute.parentRefs`          | **Required** when enabled: attachment to existing Gateway(s)        | `[]`    |
| `gatewayApi.httpRoute.hostnames`           | `HTTPRoute` `spec.hostnames`                                       | `[]`    |
| `gatewayApi.httpRoute.rules`               | Full `spec.rules`; if empty, chart generates path → Service rule   | `[]`    |
| `gatewayApi.certificate.enabled`           | Create cert-manager `Certificate` for TLS material                  | `false` |
| `gatewayApi.certificate.issuerRef.name`    | Issuer / ClusterIssuer name (required if certificate enabled)       | `""`    |

### Persistence Parameters

| Parameter                  | Description                  | Default           |
| -------------------------- | ---------------------------- | ----------------- |
| `persistence.enabled`      | Enable persistence using PVC | `false`           |
| `persistence.storageClass` | PVC Storage Class            | `""`              |
| `persistence.accessModes`  | PVC Access Mode              | `[ReadWriteOnce]` |
| `persistence.size`         | PVC Storage Request          | `8Gi`             |
| `persistence.mountPath`    | Path to mount the volume at  | `/data`           |

### Autoscaling Parameters

| Parameter                  | Description                          | Default |
| -------------------------- | ------------------------------------ | ------- |
| `autoscaling.enabled`      | Enable Horizontal POD autoscaling    | `false` |
| `autoscaling.minReplicas`  | Minimum number of replicas           | `1`     |
| `autoscaling.maxReplicas`  | Maximum number of replicas           | `11`    |
| `autoscaling.targetCPU`    | Target CPU utilization percentage    | `80`    |
| `autoscaling.targetMemory` | Target Memory utilization percentage | `80`    |

### Update Strategy Parameters

| Parameter                               | Description                                                       | Default         |
| --------------------------------------- | ----------------------------------------------------------------- | --------------- |
| `updateStrategy.type`                   | Update strategy type (RollingUpdate/Recreate/OnDelete)            | `RollingUpdate` |
| `updateStrategy.rollingUpdate.maxSurge` | Max pods that can be created over desired replicas (Deployment)   | `nil`           |
| `updateStrategy.rollingUpdate.maxUnavailable` | Max pods that can be unavailable during update              | `nil`           |
| `updateStrategy.rollingUpdate.partition` | Ordinal at which StatefulSet should be partitioned (StatefulSet) | `nil`           |

### Pod Scheduling Parameters

| Parameter                 | Description                                   | Default |
| ------------------------- | --------------------------------------------- | ------- |
| `podAffinityPreset`       | Pod affinity preset (soft/hard)               | `""`    |
| `podAntiAffinityPreset`   | Pod anti-affinity preset (soft/hard)          | `""`    |
| `nodeAffinityPreset.type` | Node affinity preset type (soft/hard)         | `""`    |
| `affinity`                | Custom affinity rules (overrides all presets) | `{}`    |
| `nodeSelector`            | Node labels for pod assignment                | `{}`    |
| `tolerations`             | Tolerations for pod assignment                | `[]`    |

### RBAC Parameters

| Parameter               | Description           | Default |
| ----------------------- | --------------------- | ------- |
| `serviceAccount.create` | Create ServiceAccount | `true`  |
| `serviceAccount.name`   | ServiceAccount name   | `""`    |
| `rbac.create`           | Create RBAC resources | `false` |
| `rbac.rules`            | Custom RBAC rules     | `[]`    |

### Extra Deploy Parameters

| Parameter      | Description                                                           | Default |
| -------------- | --------------------------------------------------------------------- | ------- |
| `extraDeploy`  | Array of extra Kubernetes objects to deploy (supports full templating) | `[]`    |

## Usage Examples

Commands that reference `./charts/generic-app` assume your shell’s current directory is the **helm-charts** repository root (the folder that contains `charts/`).

### Example 1: Simple Web Application with SSL

```yaml
# values-webapp.yaml
image:
  repository: myapp
  tag: '1.0.0'

# Automatic SSL certificate from Let's Encrypt
certManager:
  enabled: true
  issuerType: ClusterIssuer
  issuerName: letsencrypt-prod
  acme:
    enabled: true
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com

service:
  type: ClusterIP
  ports:
    http: 8080

ingress:
  enabled: true
  ingressClassName: nginx
  hostname: myapp.example.com
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  tls: true

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPU: 70
```

Install:

```bash
helm install myapp ./charts/generic-app -f charts/generic-app/examples/values-webapp-example.yaml
```

### Example 2: StatefulSet with Persistent Storage

```yaml
# values-stateful.yaml
kind: StatefulSet

image:
  repository: postgres
  tag: '15'

service:
  ports:
    postgres: 5432

persistence:
  enabled: true
  size: 20Gi
  mountPath: /var/lib/postgresql/data

podDisruptionBudget:
  enabled: true
  minAvailable: 1

resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi
```

Install:

```bash
helm install postgres ./charts/generic-app -f charts/generic-app/examples/values-stateful-example.yaml
```

### Example 3: Application with ConfigMap and Secrets

```yaml
# values-with-config.yaml
image:
  repository: myapp
  tag: '2.0.0'

configMaps:
  enabled: true
  data:
    app.env: 'production'
    log.level: 'info'
    feature.flag: 'enabled'

secrets:
  enabled: true
  data:
    db-password: 'mysecretpassword'
    api-key: 'myapikey'

# Load environment variables from chart-created ConfigMap and Secret
extraEnvVarsConfigMaps:
  - '{{ include "generic-app.fullname" . }}'

extraEnvVarsSecrets:
  - '{{ include "generic-app.fullname" . }}'

# Or load from external ConfigMaps/Secrets
# extraEnvVarsConfigMaps:
#   - app-config
#   - shared-config
# extraEnvVarsSecrets:
#   - db-credentials
#   - api-keys

livenessProbe:
  enabled: true
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30

readinessProbe:
  enabled: true
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
```

### Example 4: With Network Policy and Security Context

```yaml
# values-secure.yaml
image:
  repository: myapp
  tag: '1.0.0'

podSecurityContext:
  enabled: true
  fsGroup: 1001

containerSecurityContext:
  enabled: true
  runAsUser: 1001
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false

networkPolicy:
  enabled: true
  allowExternal: false
  extraIngress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: frontend
      ports:
        - protocol: TCP
          port: 8080

rbac:
  create: true
  rules:
    - apiGroups: ['']
      resources: ['configmaps']
      verbs: ['get', 'list']
```

### Example 5: High Availability with Pod Anti-Affinity

```yaml
# values-ha.yaml
replicaCount: 3

image:
  repository: myapp
  tag: '1.0.0'

# Spread pods across nodes for high availability
podAntiAffinityPreset: soft

# Or strict HA (requires enough nodes)
# podAntiAffinityPreset: hard

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

podDisruptionBudget:
  enabled: true
  minAvailable: 2
```

### Example 6: Custom Update Strategy for Zero-Downtime Deployment

```yaml
# values-rolling-update.yaml
replicaCount: 3

image:
  repository: myapp
  tag: '1.0.0'

# Zero-downtime rolling update strategy
# Ensures at least one pod is always available
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1          # Allow 1 extra pod during update (total 4 pods max)
    maxUnavailable: 0    # Never allow any pods to be unavailable

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

readinessProbe:
  enabled: true
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 10
  periodSeconds: 5
```

For StatefulSet with controlled rollout:

```yaml
# values-stateful-controlled.yaml
kind: StatefulSet

replicaCount: 5

image:
  repository: mydb
  tag: '1.0.0'

# Canary-style update: only update pods with ordinal >= partition
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    partition: 3        # Only update pods mydb-3 and mydb-4
    maxUnavailable: 1   # Allow 1 pod to be unavailable during update

persistence:
  enabled: true
  size: 10Gi
```

### Example 7: With Init Container and Sidecars

```yaml
# values-advanced.yaml
image:
  repository: myapp
  tag: '1.0.0'

initContainers:
  - name: init-migration
    image: myapp-migrate:1.0.0
    command: ['sh', '-c', 'migrate up']
    env:
      - name: DB_HOST
        value: 'postgres-service'

sidecars:
  - name: log-collector
    image: fluentd:latest
    volumeMounts:
      - name: logs
        mountPath: /var/log

extraVolumes:
  - name: logs
    emptyDir: {}

extraVolumeMounts:
  - name: logs
    mountPath: /var/log
```

### Example 8: Deploy Extra Resources (Jobs, CronJobs, etc.)

```yaml
# values-extra-deploy.yaml
image:
  repository: myapp
  tag: '1.0.0'

# Deploy additional Kubernetes resources
extraDeploy:
  # Database migration job (runs before app starts)
  - apiVersion: batch/v1
    kind: Job
    metadata:
      name: '{{ include "generic-app.fullname" . }}-migration'
      namespace: '{{ include "generic-app.namespace" . }}'
      labels: {{- include "generic-app.labels" . | nindent 8 }}
      annotations:
        "helm.sh/hook": pre-install,pre-upgrade
        "helm.sh/hook-weight": "-5"
        "helm.sh/hook-delete-policy": before-hook-creation
    spec:
      backoffLimit: 3
      template:
        metadata:
          name: '{{ include "generic-app.fullname" . }}-migration'
        spec:
          restartPolicy: OnFailure
          containers:
          - name: migration
            image: '{{ include "generic-app.image" . }}'
            command: ["npm", "run", "migrate"]
            env:
            - name: DATABASE_URL
              value: "postgres://db:5432/mydb"

  # Daily backup cronjob
  - apiVersion: batch/v1
    kind: CronJob
    metadata:
      name: '{{ include "generic-app.fullname" . }}-backup'
      namespace: '{{ include "generic-app.namespace" . }}'
      labels: {{- include "generic-app.labels" . | nindent 8 }}
    spec:
      schedule: "0 2 * * *"  # Daily at 2 AM
      successfulJobsHistoryLimit: 3
      failedJobsHistoryLimit: 1
      jobTemplate:
        spec:
          template:
            spec:
              restartPolicy: OnFailure
              containers:
              - name: backup
                image: postgres:15
                command:
                - /bin/sh
                - -c
                - pg_dump -h db -U postgres mydb > /backups/backup-$(date +%Y%m%d).sql
                volumeMounts:
                - name: backup-storage
                  mountPath: /backups
              volumes:
              - name: backup-storage
                persistentVolumeClaim:
                  claimName: backup-pvc

  # Prometheus ServiceMonitor for monitoring
  - apiVersion: monitoring.coreos.com/v1
    kind: ServiceMonitor
    metadata:
      name: '{{ include "generic-app.fullname" . }}'
      namespace: '{{ include "generic-app.namespace" . }}'
      labels: {{- include "generic-app.labels" . | nindent 8 }}
    spec:
      selector:
        matchLabels: {{- include "generic-app.selectorLabels" . | nindent 10 }}
      endpoints:
      - port: http
        path: /metrics
        interval: 30s
```

Install:

```bash
helm install myapp ./charts/generic-app -f charts/generic-app/examples/values-extra-deploy-example.yaml
```

## Best Practices

1. **Use specific image tags** instead of `latest` for production deployments
2. **Enable resource limits** to prevent resource exhaustion
3. **Configure health probes** for better availability and faster recovery
4. **Use Secrets** for sensitive data instead of ConfigMaps
5. **Enable HPA** for applications with variable load
6. **Set PodDisruptionBudget** for high-availability applications
7. **Use pod anti-affinity** to spread pods across nodes (`podAntiAffinityPreset: soft`)
8. **Enable NetworkPolicy** for enhanced security in production
9. **Use multiple ConfigMaps/Secrets** for better separation of concerns
10. **Separate data and application lifecycle** (external PVCs when possible)

## Customization

This chart is designed to be highly customizable. You can:

1. **Modify the Chart.yaml** to change chart metadata
2. **Update values.yaml** with your application-specific defaults
3. **Add custom templates** in the `templates/` directory
4. **Extend \_helpers.tpl** with additional helper functions
5. **Create multiple values files** for different environments (dev, staging, prod)

## Chart Structure

```
generic-app/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
├── templates/
│   ├── _helpers.tpl        # Template helpers
│   ├── deployment.yaml     # Deployment resource
│   ├── statefulset.yaml    # StatefulSet resource
│   ├── service.yaml        # Service resource
│   ├── service-headless.yaml  # Headless service for StatefulSet
│   ├── ingress.yaml        # Ingress resource
│   ├── httproute.yaml      # Gateway API HTTPRoute
│   ├── gatewayapi-certificate.yaml  # cert-manager Certificate (Gateway TLS secret)
│   ├── issuer.yaml         # Cert-manager Issuer/ClusterIssuer
│   ├── configmap.yaml      # ConfigMap resource
│   ├── secret.yaml         # Secret resource
│   ├── pvc.yaml            # PersistentVolumeClaim
│   ├── serviceaccount.yaml # ServiceAccount
│   ├── role.yaml           # Role
│   ├── rolebinding.yaml    # RoleBinding
│   ├── hpa.yaml            # HorizontalPodAutoscaler
│   ├── pdb.yaml            # PodDisruptionBudget
│   ├── networkpolicy.yaml  # NetworkPolicy
│   ├── extra-deploy.yaml   # Extra Kubernetes objects
│   └── NOTES.txt           # Installation notes
└── README.md               # This file
```

## Upgrading

```bash
# Upgrade to latest version
helm upgrade my-app quyendv/generic-app

# Upgrade with new values
helm upgrade my-app quyendv/generic-app -f my-values.yaml

# Rollback to previous version
helm rollback my-app
```

## Troubleshooting

### Check Release Status

```bash
helm list
helm status my-app
helm get values my-app
```

### Debug Installation

```bash
# Dry-run to preview manifests
helm install my-app quyendv/generic-app --dry-run --debug

# Template locally
helm template my-app ./charts/generic-app -f my-values.yaml

# Check pod logs
kubectl logs -l app.kubernetes.io/name=generic-app
```

### Common Issues

**Issue**: Image pull errors

- Check `image.repository`, `image.tag`, and `image.pullSecrets`
- Verify registry credentials

**Issue**: Pods not starting

- Check resource limits: `kubectl describe pod <pod-name>`
- Verify health probes configuration

**Issue**: Service not accessible

- Verify service type and port configuration
- Check ingress controller if using Ingress
- For Gateway API: confirm `HTTPRoute` is accepted (`kubectl describe httproute`), `ReferenceGrant` if Gateway is in another namespace, and listener TLS references the intended Secret

## CI/CD Integration

### ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
spec:
  source:
    repoURL: https://quyendv.github.io/helm-charts
    chart: generic-app
    targetRevision: 1.7.0
    helm:
      values: |
        image:
          repository: myapp
          tag: "1.0.0"
  destination:
    server: https://kubernetes.default.svc
    namespace: default
```

### FluxCD

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: quyendv
spec:
  interval: 10m
  url: https://quyendv.github.io/helm-charts
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: my-app
spec:
  chart:
    spec:
      chart: generic-app
      version: 1.7.0
      sourceRef:
        kind: HelmRepository
        name: quyendv
  values:
    image:
      repository: myapp
      tag: '1.0.0'
```

## Additional Documentation

- [Pod Affinity Examples](./examples/values-affinity-example.yaml) - Examples for pod affinity and anti-affinity configurations
- [Rolling Update Strategy Examples](./examples/values-rolling-update-example.yaml) - Examples for configuring deployment update strategies
- [Extra Deploy Examples](./examples/values-extra-deploy-example.yaml) - Examples for deploying additional Kubernetes resources (Jobs, CronJobs, ServiceMonitors, etc.)
- [Web Application Example](./examples/values-webapp-example.yaml) - Complete example for deploying a web application
- [StatefulSet Example](./examples/values-stateful-example.yaml) - Complete example for deploying a stateful application
- [Microservice Example](./examples/values-microservice-example.yaml) - Complete example for deploying a microservice
- [Gateway API Example](./examples/values-gateway-api-example.yaml) - HTTPRoute attached to an existing Gateway (optional cert-manager Certificate)

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Bitnami Charts](https://github.com/bitnami/charts)
