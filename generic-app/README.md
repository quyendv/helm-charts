# Generic Application Helm Chart

A comprehensive, production-ready Helm chart that can be used as a template for deploying various applications to Kubernetes. This chart follows best practices from major open-source projects like Bitnami.

## Features

- ✅ Support for both **Deployment** and **StatefulSet**
- ✅ Flexible **Service** configuration (ClusterIP, NodePort, LoadBalancer)
- ✅ **Ingress** with TLS support
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

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+

## Installing the Chart

To install the chart with the release name `my-app`:

```bash
helm install my-app ./generic-app
```

To install with custom values:

```bash
helm install my-app ./generic-app -f my-values.yaml
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

### Service Parameters

| Parameter             | Description             | Default      |
| --------------------- | ----------------------- | ------------ |
| `service.type`        | Kubernetes Service type | `ClusterIP`  |
| `service.ports`       | Service ports           | `{http: 80}` |
| `service.annotations` | Service annotations     | `{}`         |

### Ingress Parameters

| Parameter                  | Description                           | Default     |
| -------------------------- | ------------------------------------- | ----------- |
| `ingress.enabled`          | Enable ingress controller resource    | `false`     |
| `ingress.ingressClassName` | IngressClass name                     | `""`        |
| `ingress.hostname`         | Default host for the ingress resource | `app.local` |
| `ingress.path`             | Default path for the ingress resource | `/`         |
| `ingress.tls`              | Enable TLS configuration              | `false`     |
| `ingress.annotations`      | Ingress annotations                   | `{}`        |

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

### RBAC Parameters

| Parameter               | Description           | Default |
| ----------------------- | --------------------- | ------- |
| `serviceAccount.create` | Create ServiceAccount | `true`  |
| `serviceAccount.name`   | ServiceAccount name   | `""`    |
| `rbac.create`           | Create RBAC resources | `false` |
| `rbac.rules`            | Custom RBAC rules     | `[]`    |

## Usage Examples

### Example 1: Simple Web Application

```yaml
# values-webapp.yaml
image:
  repository: myapp
  tag: '1.0.0'

service:
  type: LoadBalancer
  ports:
    http: 8080

ingress:
  enabled: true
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
helm install myapp ./generic-app -f values-webapp.yaml
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
helm install postgres ./generic-app -f values-stateful.yaml
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

extraEnvVarsCM: '{{ include "generic-app.fullname" . }}'
extraEnvVarsSecret: '{{ include "generic-app.fullname" . }}'

livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30

readinessProbe:
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

### Example 5: With Init Container and Sidecars

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

## Best Practices

1. **Use specific image tags** instead of `latest` for production deployments
2. **Enable resource limits** to prevent resource exhaustion
3. **Configure health probes** for better availability
4. **Use Secrets** for sensitive data instead of ConfigMaps
5. **Enable HPA** for applications with variable load
6. **Set PodDisruptionBudget** for high-availability applications
7. **Use anti-affinity rules** to spread pods across nodes
8. **Enable NetworkPolicy** for enhanced security

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
│   ├── configmap.yaml      # ConfigMap resource
│   ├── secret.yaml         # Secret resource
│   ├── pvc.yaml            # PersistentVolumeClaim
│   ├── serviceaccount.yaml # ServiceAccount
│   ├── role.yaml           # Role
│   ├── rolebinding.yaml    # RoleBinding
│   ├── hpa.yaml            # HorizontalPodAutoscaler
│   ├── pdb.yaml            # PodDisruptionBudget
│   ├── networkpolicy.yaml  # NetworkPolicy
│   └── NOTES.txt           # Installation notes
└── README.md               # This file
```

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Bitnami Charts](https://github.com/bitnami/charts)
