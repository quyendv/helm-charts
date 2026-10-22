# Generic Application Helm Chart

A comprehensive, production-ready Helm chart that can be used as a template for deploying various applications to Kubernetes. This chart follows best practices from major open-source projects like Bitnami.

## Features

- ✅ Support for **Deployment**, **StatefulSet** and **DaemonSet**
- ✅ Flexible **Service** configuration (ClusterIP, NodePort, LoadBalancer)
- ✅ **Ingress** with TLS support
- ✅ **Gateway API** (`HTTPRoute`) and optional cert-manager **Certificate** for TLS secrets used by Gateways
- ✅ **Automatic SSL/TLS certificate** management with cert-manager (Let's Encrypt, CA, Vault)
- ✅ **ConfigMaps** and **Secrets** management
- ✅ **External Secrets** (`ExternalSecret`) integration for provider-backed secrets
- ✅ **ServiceMonitor** (Prometheus Operator) integration
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
- ✅ **Values schema** (`values.schema.json`) - typos and invalid values fail at install time, not silently

## Prerequisites

- Kubernetes 1.25+
- Helm 3.14+ or Helm 4

## Quick Start

### Add Helm Repository

```bash
helm repo add quyendv https://quyendv.github.io/helm-charts
helm repo update
```

### Install Chart

The chart has no default image and exposes no port by default: `image.repository` and
`image.tag` (or `image.digest`) are required, and a Service is created only when you ask for one.

```bash
# Install with custom values
helm install my-app quyendv/generic-app -f my-values.yaml

# Install specific version
helm install my-app quyendv/generic-app --version 2.0.0

# Install with inline values: an nginx container behind a ClusterIP Service on port 80
helm install my-app quyendv/generic-app \
  --set image.repository=nginx \
  --set image.tag=1.27.3 \
  --set service.enabled=true \
  --set service.ports.http=80
```

### Ports and Services

- `service.ports` maps a port **name** to the port the Service publishes. Each name is also
  the Service `targetPort`, so it must match a container port name.
- `containerPorts` maps names to the ports the container listens on. Leave it empty and the
  container mirrors `service.ports`; set it when the numbers differ or when the pod listens on
  ports the Service does not publish:

  ```yaml
  service:
    enabled: true
    ports:
      http: 80        # clients call <service>:80
  containerPorts:
    http: 8080        # the app listens on 8080
    admin: 9000       # reachable on the pod only
  ```

- Ingress and Gateway API route to the `http` port, or to the only port when there is one.
  With several ports and none named `http`, name the one to use in `ingress.servicePort` /
  `gatewayApi.httpRoute.servicePort`.
- A worker with no Service needs no port configuration at all.


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

> **Data is retained by default.** `helm uninstall` does **not** delete your PersistentVolumeClaims:
>
> - **Deployment / DaemonSet**: the chart-managed PVC carries `helm.sh/resource-policy: keep` (`persistence.resourcePolicy`, default `keep`). Set `persistence.resourcePolicy=""` to let Helm delete it on uninstall.
> - **StatefulSet**: PVCs come from `volumeClaimTemplates` and are governed by Kubernetes, which retains them by default. Use `persistence.persistentVolumeClaimRetentionPolicy` (k8s 1.27+) to opt into automatic cleanup.
>
> To remove retained data manually: `kubectl delete pvc -l app.kubernetes.io/instance=my-app`

### PVC retention: Helm vs Argo CD

Data is kept by default in both runtimes, but the mechanism differs.

**Plain Helm** (`helm install` / `upgrade` / `uninstall`):

- The `helm.sh/resource-policy: keep` annotation is read by the Helm client, so `helm uninstall` skips the PVC.

**Argo CD** (renders with `helm template` — there is no Helm release, so `helm uninstall` never runs):

- Argo CD **does** honor `helm.sh/resource-policy: keep`, treating it as equivalent to `argocd.argoproj.io/sync-options: Delete=false`.
- That protects the PVC on **Application deletion** (cascade delete) — the analog of `helm uninstall`. ✅
- It does **not** imply `Prune=false`. If the PVC is removed from the rendered output (e.g. you set `persistence.enabled=false`) while the Application still exists and auto-prune is on, Argo CD **will prune it**. To also prevent that, opt in via `persistence.annotations`:

  ```yaml
  persistence:
    resourcePolicy: keep
    annotations:
      argocd.argoproj.io/sync-options: Prune=false
  ```

| Deletion path | Helm | Argo CD | Protected by `keep`? |
| --- | --- | --- | --- |
| Uninstall / App delete | `helm uninstall` | cascade delete | ✅ |
| Removed from source (drift) | — (no such concept) | prune | ❌ — add `Prune=false` |

> The chart intentionally does **not** auto-inject `argocd.argoproj.io/sync-options` annotations: `Delete=false` would be redundant with `keep`, and `Prune=false` is a stronger, different policy (it leaves the Application `OutOfSync` when a resource is legitimately removed) that should be an explicit opt-in.

**Cleanest for a pre-existing PVC** (adopting a workload into the chart): set `persistence.existingClaim: <name>`. The chart then only *references* the PVC (it is not rendered or owned), so neither Helm nor Argo CD ever deletes or prunes it — and no ownership/adoption step is needed.

## Parameters

### Global parameters

| Name                      | Description                                     | Value |
| ------------------------- | ----------------------------------------------- | ----- |
| `global.imageRegistry`    | Global Docker image registry                    | `""`  |
| `global.imagePullSecrets` | Global Docker registry secret names as an array | `[]`  |
| `global.storageClass`     | Global StorageClass for Persistent Volume(s)    | `""`  |

### Common parameters

| Name                | Description                                        | Value |
| ------------------- | -------------------------------------------------- | ----- |
| `nameOverride`      | String to partially override common.names.fullname | `""`  |
| `fullnameOverride`  | String to fully override common.names.fullname     | `""`  |
| `namespaceOverride` | String to fully override common.names.namespace    | `""`  |
| `commonLabels`      | Labels to add to all deployed objects              | `{}`  |
| `commonAnnotations` | Annotations to add to all deployed objects         | `{}`  |

### Application parameters

| Name                     | Description                                                                                                                            | Value        |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| `replicaCount`           | Number of replicas to deploy                                                                                                           | `1`          |
| `kind`                   | Workload kind (Deployment, StatefulSet, or DaemonSet)                                                                                  | `Deployment` |
| `image.registry`         | Application image registry (empty uses the runtime default, normally docker.io)                                                        | `""`         |
| `image.repository`       | Application image repository (REQUIRED)                                                                                                | `""`         |
| `image.tag`              | Application image tag (immutable tags are recommended)                                                                                 | `""`         |
| `image.digest`           | Application image digest, e.g. sha256:abc... (pins the image; may be combined with tag)                                                | `""`         |
| `image.pullPolicy`       | Application image pull policy                                                                                                          | `""`         |
| `image.pullSecrets`      | Application image pull secrets                                                                                                         | `[]`         |
| `command`                | Override default container command (useful when using custom images)                                                                   | `[]`         |
| `args`                   | Override default container args (useful when using custom images)                                                                      | `[]`         |
| `containerPorts`         | Container ports map (name -> number), independent of service.ports; falls back to service.ports when empty and service.enabled is true | `{}`         |
| `extraEnvVars`           | Array with extra environment variables to add                                                                                          | `[]`         |
| `extraEnvVarsConfigMaps` | List of existing ConfigMaps to load as environment variables                                                                           | `[]`         |
| `extraEnvVarsSecrets`    | List of existing Secrets to load as environment variables                                                                              | `[]`         |

### Security parameters

| Name                                                | Description                                                                                               | Value   |
| --------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------- |
| `containerSecurityContext.enabled`                  | Enable container security context                                                                         | `false` |
| `containerSecurityContext.runAsUser`                | UID to run the container process as. Any non-zero integer; avoid 0 (root)                                 |         |
| `containerSecurityContext.runAsGroup`               | Primary GID for the container process. Any integer (commonly matches runAsUser)                           |         |
| `containerSecurityContext.runAsNonRoot`             | Reject the container at startup if the image would run as UID 0. true / false                             |         |
| `containerSecurityContext.readOnlyRootFilesystem`   | Mount the container root filesystem read-only (use emptyDir/volumes for writable paths). true / false     |         |
| `containerSecurityContext.allowPrivilegeEscalation` | Allow a process to gain more privileges than its parent (setuid binaries, sudo). Keep false. true / false |         |
| `containerSecurityContext.privileged`               | Give the container near-host privileges. Almost never needed. true / false                                |         |
| `containerSecurityContext.capabilities`             | Linux capabilities to drop/add (drop ["ALL"] then add only what is required, e.g. NET_BIND_SERVICE)       |         |
| `containerSecurityContext.seccompProfile`           | Seccomp profile. type: RuntimeDefault / Localhost / Unconfined (Localhost also needs localhostProfile)    |         |
| `podSecurityContext.enabled`                        | Enable pod security context                                                                               | `false` |
| `podSecurityContext.runAsUser`                      | Default UID for all containers (a container-level runAsUser overrides this). Non-zero integer             |         |
| `podSecurityContext.runAsGroup`                     | Default primary GID for all containers. Integer                                                           |         |
| `podSecurityContext.runAsNonRoot`                   | Require all containers to run as non-root. true / false                                                   |         |
| `podSecurityContext.fsGroup`                        | Supplemental GID that owns mounted volumes; the kubelet chowns volume contents to this GID. Integer       |         |
| `podSecurityContext.fsGroupChangePolicy`            | When to apply fsGroup ownership to volumes. Always / OnRootMismatch (faster on large volumes)             |         |
| `podSecurityContext.supplementalGroups`             | Extra GIDs added to the first process of each container. List of integers                                 |         |
| `podSecurityContext.seccompProfile`                 | Pod-wide seccomp profile. type: RuntimeDefault / Localhost / Unconfined                                   |         |
| `podSecurityContext.sysctls`                        | Namespaced kernel sysctls to set (name/value pairs); only "safe" sysctls unless the node allows more      |         |

### Service parameters

| Name                               | Description                                                                                                | Value       |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------- | ----------- |
| `service.enabled`                  | Enable service creation (requires at least one entry in service.ports)                                     | `false`     |
| `service.type`                     | Service type                                                                                               | `ClusterIP` |
| `service.ports`                    | Service ports map (name -> port). Each name is also the targetPort, so it must match a container port name | `{}`        |
| `service.nodePorts`                | Node ports by service.ports name, for NodePort/LoadBalancer services (30000-32767)                         | `{}`        |
| `service.clusterIP`                | Service Cluster IP                                                                                         | `""`        |
| `service.loadBalancerIP`           | Service Load Balancer IP                                                                                   | `""`        |
| `service.loadBalancerSourceRanges` | Service Load Balancer sources                                                                              | `[]`        |
| `service.externalTrafficPolicy`    | Service external traffic policy                                                                            | `Cluster`   |
| `service.annotations`              | Additional custom annotations for Service                                                                  | `{}`        |
| `service.extraPorts`               | Extra ports to expose in Service (normally used with the `sidecars` value)                                 | `[]`        |
| `service.sessionAffinity`          | Session Affinity for Kubernetes service, can be "None" or "ClientIP"                                       | `None`      |
| `service.sessionAffinityConfig`    | Additional settings for the sessionAffinity                                                                | `{}`        |

### Cert-Manager parameters

| Name                                    | Description                                          | Value                                            |
| --------------------------------------- | ---------------------------------------------------- | ------------------------------------------------ |
| `certManager.enabled`                   | Enable cert-manager issuer creation                  | `false`                                          |
| `certManager.issuerType`                | Type of issuer to create (Issuer or ClusterIssuer)   | `ClusterIssuer`                                  |
| `certManager.issuerName`                | Name of the issuer (if empty, will use release name) | `""`                                             |
| `certManager.acme.enabled`              | Enable ACME issuer (Let's Encrypt)                   | `true`                                           |
| `certManager.acme.server`               | ACME server URL                                      | `https://acme-v02.api.letsencrypt.org/directory` |
| `certManager.acme.email`                | Email address for ACME registration                  | `""`                                             |
| `certManager.acme.privateKeySecretRef`  | Secret name to store ACME account private key        | `""`                                             |
| `certManager.acme.solvers`              | HTTP01 solver configuration                          | `[]`                                             |
| `certManager.ca.enabled`                | Enable CA issuer                                     | `false`                                          |
| `certManager.ca.secretName`             | Secret name containing CA certificate and key        | `""`                                             |
| `certManager.vault.enabled`             | Enable Vault issuer                                  | `false`                                          |
| `certManager.vault.server`              | Vault server URL                                     | `""`                                             |
| `certManager.vault.path`                | Vault PKI path                                       | `""`                                             |
| `certManager.vault.caBundle`            | CA bundle for Vault server                           | `""`                                             |
| `certManager.vault.auth.tokenSecretRef` | Token secret reference                               | `{}`                                             |

### Ingress parameters

| Name                       | Description                                                                                                                      | Value    |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | -------- |
| `ingress.enabled`          | Enable ingress record generation                                                                                                 | `false`  |
| `ingress.ingressClassName` | IngressClass that will be be used to implement the Ingress (Kubernetes 1.18+)                                                    | `""`     |
| `ingress.pathType`         | Ingress path type (Prefix behaves the same on every controller; ImplementationSpecific does not)                                 | `Prefix` |
| `ingress.hostname`         | Default host for the ingress record (required unless extraHosts or extraRules are set)                                           | `""`     |
| `ingress.servicePort`      | Name of the service.ports entry to route to (empty: "http", or the only port)                                                    | `""`     |
| `ingress.path`             | Default path for the ingress record                                                                                              | `/`      |
| `ingress.annotations`      | Additional annotations for the Ingress resource. To enable certificate autogeneration, place here your cert-manager annotations. | `{}`     |
| `ingress.tls`              | Enable TLS configuration for the host defined at `ingress.hostname` parameter                                                    | `false`  |
| `ingress.extraHosts`       | An array with additional hostname(s) to be covered with the ingress record                                                       | `[]`     |
| `ingress.extraPaths`       | An array with additional arbitrary paths that may need to be added to the ingress under the main host                            | `[]`     |
| `ingress.extraTls`         | TLS configuration for additional hostname(s) to be covered with this ingress record                                              | `[]`     |
| `ingress.extraRules`       | Additional rules to be covered with this ingress record                                                                          | `[]`     |

### Gateway API parameters

| Name                                                          | Description                                                                                                                                   | Value   |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `gatewayApi.enabled`                                          | Create HTTPRoute (and optional Certificate) for Gateway API                                                                                   | `false` |
| `gatewayApi.apiVersion`                                       | HTTPRoute API version (leave empty for gateway.networking.k8s.io/v1)                                                                          | `""`    |
| `gatewayApi.hostname`                                         | Convenience hostname (appended to httpRoute.hostnames for route + cert)                                                                       | `""`    |
| `gatewayApi.httpRoute.name`                                   | HTTPRoute resource name (defaults to release fullname)                                                                                        | `""`    |
| `gatewayApi.httpRoute.annotations`                            | HTTPRoute annotations                                                                                                                         | `{}`    |
| `gatewayApi.httpRoute.labels`                                 | Extra labels for HTTPRoute                                                                                                                    | `{}`    |
| `gatewayApi.httpRoute.parentRefs`                             | Attach to existing Gateway(s) / GatewayClass via standard parentRefs                                                                          | `[]`    |
| `gatewayApi.httpRoute.hostnames`                              | HTTPRoute spec.hostnames (SNI / Host header routing)                                                                                          | `[]`    |
| `gatewayApi.httpRoute.path`                                   | Default path match when rules is empty (PathPrefix)                                                                                           | `{}`    |
| `gatewayApi.httpRoute.servicePort`                            | Name of the service.ports entry the default rule routes to (empty: "http", or the only port). Ignored when rules is set                       | `""`    |
| `gatewayApi.httpRoute.timeouts`                               | Timeouts injected into the generated default rule (only when rules is empty). Ignored when rules is set — put timeouts per-rule there instead | `{}`    |
| `gatewayApi.httpRoute.rules`                                  | Full HTTPRoute spec.rules (if non-empty, overrides default path/backend rule).                                                                | `[]`    |
| `gatewayApi.httpRoute.extraRules`                             | Rendered YAML appended after generated rules (advanced)                                                                                       | `""`    |
| `gatewayApi.httpRedirect.enabled`                             | Create an extra HTTPRoute that redirects requests to HTTPS                                                                                    | `false` |
| `gatewayApi.httpRedirect.name`                                | Redirect HTTPRoute resource name (defaults to fullname + "-http-redirect")                                                                    | `""`    |
| `gatewayApi.httpRedirect.annotations`                         | Redirect HTTPRoute annotations                                                                                                                | `{}`    |
| `gatewayApi.httpRedirect.labels`                              | Extra labels for redirect HTTPRoute                                                                                                           | `{}`    |
| `gatewayApi.httpRedirect.parentRefs`                          | ParentRefs for redirect route (typically HTTP listener, e.g. sectionName: http)                                                               | `[]`    |
| `gatewayApi.httpRedirect.hostnames`                           | Redirect route hostnames (defaults to effective route hostnames when empty)                                                                   | `[]`    |
| `gatewayApi.httpRedirect.path`                                | Match path for redirect route                                                                                                                 | `{}`    |
| `gatewayApi.httpRedirect.scheme`                              | Redirect target scheme                                                                                                                        | `https` |
| `gatewayApi.httpRedirect.statusCode`                          | Redirect status code                                                                                                                          | `301`   |
| `gatewayApi.certificate.enabled`                              | Create cert-manager.io/v1 Certificate                                                                                                         | `false` |
| `gatewayApi.certificate.name`                                 | Certificate resource name (defaults to fullname + "-gateway-tls")                                                                             | `""`    |
| `gatewayApi.certificate.annotations`                          | Certificate annotations                                                                                                                       | `{}`    |
| `gatewayApi.certificate.secretName`                           | Kubernetes Secret name for TLS material (defaults to first hostname + "-tls", else fullname + "-gateway-tls")                                 | `""`    |
| `gatewayApi.certificate.issuerRef`                            | cert-manager issuer reference (production: ClusterIssuer)                                                                                     | `{}`    |
| `gatewayApi.certificate.dnsNames`                             | Certificate spec.dnsNames (defaults to effective HTTPRoute hostnames)                                                                         | `[]`    |
| `gatewayApi.certificate.duration`                             | Optional certificate duration (e.g. 2160h)                                                                                                    | `""`    |
| `gatewayApi.certificate.renewBefore`                          | Optional renew before (e.g. 360h)                                                                                                             | `""`    |
| `gatewayApi.nginxGatewayFabric.enabled`                       | Turn on NGF policy/snippet resources (requires gatewayApi.enabled)                                                                            | `false` |
| `gatewayApi.nginxGatewayFabric.clientSettings.bodyMaxSize`    | Maps to client_max_body_size (e.g. 1024m). Empty = omit policy.                                                                               | `""`    |
| `gatewayApi.nginxGatewayFabric.upstreamProxyTimeouts.connect` | e.g. 600s                                                                                                                                     | `""`    |
| `gatewayApi.nginxGatewayFabric.upstreamProxyTimeouts.read`    | e.g. 600s                                                                                                                                     | `""`    |
| `gatewayApi.nginxGatewayFabric.upstreamProxyTimeouts.send`    | e.g. 600s                                                                                                                                     | `""`    |
| `gatewayApi.nginxGatewayFabric.snippets.extra`                | List of { context, value } maps (NGF SnippetsFilter item shape)                                                                               | `[]`    |

### Resources parameters

| Name                                 | Description                                                            | Value   |
| ------------------------------------ | ---------------------------------------------------------------------- | ------- |
| `resources`                          | Container resource requests and limits (empty: none set)               | `{}`    |
| `livenessProbe.enabled`              | Enable livenessProbe on containers                                     | `false` |
| `livenessProbe.httpGet`              | HTTP GET probe configuration (path and port)                           | `{}`    |
| `livenessProbe.initialDelaySeconds`  | Initial delay seconds for livenessProbe                                | `30`    |
| `livenessProbe.periodSeconds`        | Period seconds for livenessProbe                                       | `10`    |
| `livenessProbe.timeoutSeconds`       | Timeout seconds for livenessProbe                                      | `5`     |
| `livenessProbe.failureThreshold`     | Failure threshold for livenessProbe                                    | `6`     |
| `livenessProbe.successThreshold`     | Success threshold for livenessProbe                                    | `1`     |
| `readinessProbe.enabled`             | Enable readinessProbe on containers                                    | `false` |
| `readinessProbe.httpGet`             | HTTP GET probe configuration (path and port)                           | `{}`    |
| `readinessProbe.initialDelaySeconds` | Initial delay seconds for readinessProbe                               | `5`     |
| `readinessProbe.periodSeconds`       | Period seconds for readinessProbe                                      | `10`    |
| `readinessProbe.timeoutSeconds`      | Timeout seconds for readinessProbe                                     | `5`     |
| `readinessProbe.failureThreshold`    | Failure threshold for readinessProbe                                   | `6`     |
| `readinessProbe.successThreshold`    | Success threshold for readinessProbe                                   | `1`     |
| `startupProbe.enabled`               | Enable startupProbe on containers                                      | `false` |
| `startupProbe.httpGet`               | HTTP GET probe configuration (path and port)                           | `{}`    |
| `startupProbe.initialDelaySeconds`   | Initial delay seconds for startupProbe                                 | `0`     |
| `startupProbe.periodSeconds`         | Period seconds for startupProbe                                        | `10`    |
| `startupProbe.timeoutSeconds`        | Timeout seconds for startupProbe                                       | `5`     |
| `startupProbe.failureThreshold`      | Failure threshold for startupProbe                                     | `30`    |
| `startupProbe.successThreshold`      | Success threshold for startupProbe                                     | `1`     |
| `customLivenessProbe`                | Custom livenessProbe that overrides the default one                    | `{}`    |
| `customReadinessProbe`               | Custom readinessProbe that overrides the default one                   | `{}`    |
| `customStartupProbe`                 | Custom startupProbe that overrides the default one                     | `{}`    |
| `lifecycleHooks`                     | for the container(s) to automate configuration before or after startup | `{}`    |

### Persistence parameters

| Name                                               | Description                                                                                                                                             | Value               |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `persistence.enabled`                              | Enable persistence using Persistent Volume Claims                                                                                                       | `false`             |
| `persistence.storageClass`                         | Storage class of backing PVC                                                                                                                            | `""`                |
| `persistence.annotations`                          | Persistent Volume Claim annotations                                                                                                                     | `{}`                |
| `persistence.accessModes`                          | Persistent Volume Access Modes                                                                                                                          | `["ReadWriteOnce"]` |
| `persistence.size`                                 | Size of data volume                                                                                                                                     | `8Gi`               |
| `persistence.existingClaim`                        | The name of an existing PVC to use for persistence                                                                                                      | `""`                |
| `persistence.selector`                             | Selector to match an existing Persistent Volume for PVC                                                                                                 | `{}`                |
| `persistence.dataSource`                           | Custom PVC data source                                                                                                                                  | `{}`                |
| `persistence.mountPath`                            | The path the volume will be mounted at                                                                                                                  | `/data`             |
| `persistence.subPath`                              | The subdirectory of the volume to mount to                                                                                                              | `""`                |
| `persistence.resourcePolicy`                       | Keep the chart-managed PVC on `helm uninstall` (Deployment only). Set `helm.sh/resource-policy` annotation; "keep" retains data, "" lets Helm delete it | `keep`              |
| `persistence.persistentVolumeClaimRetentionPolicy` | StatefulSet PVC retention policy (Kubernetes 1.27+). Controls whether volumeClaimTemplates PVCs are deleted on StatefulSet scale-down/delete            | `{}`                |
| `persistence.extraVolumeClaimTemplates`            | Additional StatefulSet volumeClaimTemplates, appended after the default `data` claim (StatefulSet only)                                                 | `[]`                |

### Volume Permissions parameters

| Name                | Description                                                                   | Value |
| ------------------- | ----------------------------------------------------------------------------- | ----- |
| `initContainers`    | Add additional init containers to the pods                                    | `[]`  |
| `sidecars`          | Add additional sidecar containers to the pods                                 | `[]`  |
| `extraVolumes`      | Optionally specify extra list of additional volumes for the pods              | `[]`  |
| `extraVolumeMounts` | Optionally specify extra list of additional volumeMounts for the container(s) | `[]`  |

### ConfigMap parameters

| Name                     | Description           | Value   |
| ------------------------ | --------------------- | ------- |
| `configMaps.enabled`     | Enable ConfigMaps     | `false` |
| `configMaps.data`        | ConfigMap data        | `{}`    |
| `configMaps.annotations` | ConfigMap annotations | `{}`    |

### Secret parameters

| Name                  | Description        | Value   |
| --------------------- | ------------------ | ------- |
| `secrets.enabled`     | Enable Secrets     | `false` |
| `secrets.data`        | Secret data        | `{}`    |
| `secrets.annotations` | Secret annotations | `{}`    |

### External Secrets parameters

| Name                                   | Description                                                                                                                                                                                                          | Value                    |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| `externalSecret.enabled`               | Create an ExternalSecret resource (requires External Secrets Operator)                                                                                                                                               | `false`                  |
| `externalSecret.apiVersion`            | ExternalSecret API version (override for clusters on older External Secrets Operator releases, e.g. external-secrets.io/v1beta1)                                                                                     | `external-secrets.io/v1` |
| `externalSecret.name`                  | Name of the ExternalSecret object itself. Empty defaults to the chart fullname. Set this to adopt an ExternalSecret that already exists under a different name -- renaming it would delete and recreate the resource | `""`                     |
| `externalSecret.refreshInterval`       | How often to sync values from the provider (e.g. 1h, 15m, 0 to disable)                                                                                                                                              | `1h`                     |
| `externalSecret.secretStoreRef.name`   | Name of the SecretStore / ClusterSecretStore to pull from                                                                                                                                                            | `""`                     |
| `externalSecret.secretStoreRef.kind`   | Store kind: SecretStore or ClusterSecretStore                                                                                                                                                                        | `SecretStore`            |
| `externalSecret.target.name`           | Name of the Secret to create. Empty defaults to the chart fullname                                                                                                                                                   | `""`                     |
| `externalSecret.target.creationPolicy` | How the target Secret is created: Owner, Orphan, Merge or None                                                                                                                                                       | `Owner`                  |
| `externalSecret.target.deletionPolicy` | What happens to the Secret when the ExternalSecret is deleted: Retain, Delete or Merge                                                                                                                               | `Retain`                 |
| `externalSecret.target.template`       | Optional target template (set Secret type, render templated keys)                                                                                                                                                    | `{}`                     |
| `externalSecret.data`                  | Explicit key mappings, e.g. [{ secretKey: DB_PASS, remoteRef: { key: prod/db, property: password } }]                                                                                                                | `[]`                     |
| `externalSecret.dataFrom`              | Bulk import, e.g. [{ extract: { key: prod/db } }] or [{ find: { name: { regexp: "^prod/" } } }]                                                                                                                      | `[]`                     |
| `externalSecret.annotations`           | Additional annotations for the ExternalSecret                                                                                                                                                                        | `{}`                     |
| `externalSecret.labels`                | Additional labels for the ExternalSecret                                                                                                                                                                             | `{}`                     |

### RBAC parameters

| Name                                          | Description                                                                       | Value   |
| --------------------------------------------- | --------------------------------------------------------------------------------- | ------- |
| `serviceAccount.create`                       | Specifies whether a ServiceAccount should be created                              | `true`  |
| `serviceAccount.name`                         | The name of the ServiceAccount to use.                                            | `""`    |
| `serviceAccount.annotations`                  | Additional Service Account annotations (evaluated as a template)                  | `{}`    |
| `serviceAccount.automountServiceAccountToken` | Mount an API token into the pod (set on both the ServiceAccount and the pod spec) | `false` |
| `rbac.create`                                 | Specifies whether RBAC resources should be created                                | `false` |
| `rbac.rules`                                  | Custom RBAC rules to set                                                          | `[]`    |

### Autoscaling parameters

| Name                       | Description                          | Value   |
| -------------------------- | ------------------------------------ | ------- |
| `autoscaling.enabled`      | Enable Horizontal POD autoscaling    | `false` |
| `autoscaling.minReplicas`  | Minimum number of replicas           | `1`     |
| `autoscaling.maxReplicas`  | Maximum number of replicas           | `11`    |
| `autoscaling.targetCPU`    | Target CPU utilization percentage    | `80`    |
| `autoscaling.targetMemory` | Target Memory utilization percentage | `80`    |

### Pod Disruption Budget parameters

| Name                                 | Description                                                                                                 | Value   |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------- | ------- |
| `podDisruptionBudget.enabled`        | Enable PodDisruptionBudget                                                                                  | `false` |
| `podDisruptionBudget.minAvailable`   | Min number of pods that must still be available after the eviction                                          | `1`     |
| `podDisruptionBudget.maxUnavailable` | Max number of pods that can be unavailable after the eviction (takes precedence over minAvailable when set) | `""`    |

### Network Policy parameters

| Name                          | Description                | Value   |
| ----------------------------- | -------------------------- | ------- |
| `networkPolicy.enabled`       | Enable NetworkPolicy       | `false` |
| `networkPolicy.allowExternal` | Allow external connections | `true`  |
| `networkPolicy.extraIngress`  | Additional ingress rules   | `[]`    |
| `networkPolicy.extraEgress`   | Additional egress rules    | `[]`    |

### ServiceMonitor parameters

| Name                               | Description                                                                                          | Value      |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------- | ---------- |
| `serviceMonitor.enabled`           | Create a ServiceMonitor resource for Prometheus Operator                                             | `false`    |
| `serviceMonitor.port`              | Service port name to scrape. Must exist in service.ports.                                            | `metrics`  |
| `serviceMonitor.path`              | HTTP path to scrape metrics from                                                                     | `/metrics` |
| `serviceMonitor.interval`          | Scrape interval. Empty string inherits Prometheus Operator default.                                  | `""`       |
| `serviceMonitor.scrapeTimeout`     | Scrape timeout. Empty string inherits Prometheus Operator default.                                   | `""`       |
| `serviceMonitor.labels`            | Extra labels on the ServiceMonitor metadata.                                                         | `{}`       |
| `serviceMonitor.annotations`       | Annotations on the ServiceMonitor metadata                                                           | `{}`       |
| `serviceMonitor.honorLabels`       | Honor labels from the scrape target                                                                  | `false`    |
| `serviceMonitor.jobLabel`          | Name of the Service label to use as the Prometheus job name.                                         | `""`       |
| `serviceMonitor.relabelings`       | RelabelConfig entries applied before ingestion                                                       | `[]`       |
| `serviceMonitor.scheme`            | HTTP scheme for scraping. Valid values: http, https. Empty = use Prometheus Operator default (http). | `""`       |
| `serviceMonitor.metricRelabelings` | MetricRelabelConfig entries applied after scrape                                                     | `[]`       |

### Pod parameters

| Name                                          | Description                                                                                                                                | Value           |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| `podLabels`                                   | Extra labels for pods                                                                                                                      | `{}`            |
| `podAnnotations`                              | Annotations for pods                                                                                                                       | `{}`            |
| `podAffinityPreset`                           | Pod affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                        | `""`            |
| `podAntiAffinityPreset`                       | Pod anti-affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                   | `""`            |
| `nodeAffinityPreset.type`                     | Node affinity preset type. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                  | `""`            |
| `nodeAffinityPreset.key`                      | Node label key to match. Ignored if `affinity` is set                                                                                      | `""`            |
| `nodeAffinityPreset.values`                   | Node label values to match. Ignored if `affinity` is set                                                                                   | `[]`            |
| `affinity`                                    | Affinity for pods assignment                                                                                                               | `{}`            |
| `nodeSelector`                                | Node labels for pods assignment                                                                                                            | `{}`            |
| `tolerations`                                 | Tolerations for pods assignment                                                                                                            | `[]`            |
| `updateStrategy.type`                         | statefulset/deployment strategy type                                                                                                       | `RollingUpdate` |
| `updateStrategy.rollingUpdate.maxSurge`       | Maximum number of pods that can be created over desired replicas (Deployment only). Uncomment under `updateStrategy.rollingUpdate` to use. |                 |
| `updateStrategy.rollingUpdate.maxUnavailable` | Maximum number of pods that can be unavailable during update. Uncomment under `updateStrategy.rollingUpdate` to use.                       |                 |
| `updateStrategy.rollingUpdate.partition`      | Ordinal at which StatefulSet should be partitioned (StatefulSet only). Uncomment under `updateStrategy.rollingUpdate` to use.              |                 |
| `minReadySeconds`                             | Min seconds a new Pod must be ready before considered available (Deployment and DaemonSet)                                                 | `0`             |
| `priorityClassName`                           | pods' priorityClassName                                                                                                                    | `""`            |
| `topologySpreadConstraints`                   | Topology Spread Constraints for pod assignment spread across your cluster among failure-domains                                            | `[]`            |
| `schedulerName`                               | Name of the k8s scheduler (other than default) for pods                                                                                    | `""`            |
| `terminationGracePeriodSeconds`               | Seconds pod needs to terminate gracefully (empty uses the Kubernetes default of 30; 0 is honoured)                                         | `""`            |
| `runtimeClassName`                            | Runtime Class Name for pods                                                                                                                | `""`            |
| `hostAliases`                                 | pods host aliases                                                                                                                          | `[]`            |
| `extraDeploy`                                 | Array of extra objects to deploy with the release (supports templating)                                                                    | `[]`            |

### Custom values

| Name          | Description                                                               | Value |
| ------------- | ------------------------------------------------------------------------- | ----- |
| `extraValues` | Free-form values for your own templates (extraDeploy, tpl-enabled fields) | `{}`  |

## Gateway API notes

These operational notes complement the `gatewayApi.*` parameters above; they cover behavior that the parameter table cannot express on its own.

**NGINX Gateway Fabric (optional presets)** — active when `gatewayApi.nginxGatewayFabric.enabled` is `true` (requires `gatewayApi.enabled`). The chart renders NGF resources alongside the single chart-managed `HTTPRoute`:

- Cluster must provide `gateway.nginx.org` CRDs (`ClientSettingsPolicy`, `SnippetsFilter`). Snippets require the NGF control plane to be installed with **snippets enabled** (Helm value `nginxGateway.snippets.enable: true`).
- One shared `SnippetsFilter` per release is named `{{ release fullname }}-ngf-snippets` (63-char safe). The chart injects a single `HTTPRoute` `ExtensionRef` to it only when using the **generated default rule** (`gatewayApi.httpRoute.rules` empty). If you set full `gatewayApi.httpRoute.rules` yourself, add the `ExtensionRef` filter in your rules or use `extraDeploy`.
- For HTTP → HTTPS migration, enable `gatewayApi.httpRedirect` to create an additional redirect-only `HTTPRoute` attached to your HTTP listener.

**Timeouts** — set `gatewayApi.httpRoute.timeouts` (`request` / `backendRequest`) to add rule timeouts to the generated default rule without rewriting `matches`/`backendRefs`:

```yaml
gatewayApi:
  enabled: true
  httpRoute:
    parentRefs:
      - name: my-gateway
        namespace: gateway-system
    timeouts:
      request: 180s        # total client-facing timeout
      backendRequest: 180s # per-try timeout to the backend (<= request)
```

Like `httpRoute.path`, this only applies to the auto-generated rule. If you author full `gatewayApi.httpRoute.rules`, put `timeouts` on each rule yourself.

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
  enabled: true
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
  enabled: true
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

# The probes below target the port named "http"
containerPorts:
  http: 8080

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

# The Role is useless without an API token in the pod (off by default)
serviceAccount:
  automountServiceAccountToken: true

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

containerPorts:
  http: 8080

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

Items that template a **mapping** (labels, selectors) must be block-scalar strings (`- |`);
plain map items can only template scalar fields. See the `extraDeploy` parameter for details.

```yaml
# values-extra-deploy.yaml
image:
  repository: myapp
  tag: '1.0.0'

# Values your own templates read go under extraValues (the schema rejects unknown top-level keys)
extraValues:
  databaseUrl: postgres://db:5432/mydb

extraDeploy:
  # Database migration job (runs before the app is upgraded)
  - |
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: {{ include "generic-app.fullname" . }}-migration
      namespace: {{ include "generic-app.namespace" . }}
      labels: {{- include "generic-app.labels" . | nindent 8 }}
      annotations:
        "helm.sh/hook": pre-install,pre-upgrade
        "helm.sh/hook-weight": "-5"
        "helm.sh/hook-delete-policy": before-hook-creation
    spec:
      backoffLimit: 3
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: migration
              image: {{ include "generic-app.image" . }}
              command: ["npm", "run", "migrate"]
              env:
                - name: DATABASE_URL
                  value: {{ .Values.extraValues.databaseUrl | quote }}

  # Daily backup CronJob (fully static apart from scalar fields)
  - apiVersion: batch/v1
    kind: CronJob
    metadata:
      name: '{{ include "generic-app.fullname" . }}-backup'
    spec:
      schedule: "0 2 * * *"
      jobTemplate:
        spec:
          template:
            spec:
              restartPolicy: OnFailure
              containers:
                - name: backup
                  image: postgres:16
                  command: ["/bin/sh", "-c", "pg_dump -h db -U postgres mydb > /backups/backup-$(date +%Y%m%d).sql"]
                  volumeMounts:
                    - name: backup-storage
                      mountPath: /backups
              volumes:
                - name: backup-storage
                  persistentVolumeClaim:
                    claimName: backup-pvc
```

> For metrics, prefer the built-in `serviceMonitor.*` values over a hand-written ServiceMonitor.

Install:

```bash
helm install myapp ./charts/generic-app -f charts/generic-app/examples/values-extra-deploy-example.yaml
```

### Example 9: Pull Secrets from a Provider with External Secrets

```yaml
# values-external-secret.yaml
image:
  repository: myapp
  tag: '1.0.0'

externalSecret:
  enabled: true
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  # Materialized Secret defaults to the release fullname
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: prod/myapp/db
        property: password
  # Or import everything under a path at once:
  dataFrom:
    - extract:
        key: prod/myapp/config

# Load the operator-created Secret into the app as env vars
extraEnvVarsSecrets:
  - '{{ include "generic-app.fullname" . }}'
```

> Requires the [External Secrets Operator](https://external-secrets.io/) and a `SecretStore`/`ClusterSecretStore` in the cluster. The operator creates the target Secret asynchronously, so the Pod starts only once that Secret exists. Secret rotation in the provider does not auto-restart Pods — use a reloader controller if you need that. For multiple `ExternalSecret`s, `PushSecret`, or generators, use `extraDeploy`.

### Example 10: StatefulSet with Multiple volumeClaimTemplates

```yaml
# values-multi-pvc.yaml
kind: StatefulSet

image:
  repository: postgres
  tag: '15'

# Default "data" claim (mounted at persistence.mountPath)
persistence:
  enabled: true
  size: 20Gi
  mountPath: /var/lib/postgresql/data
  # Extra per-replica claims, appended after "data"
  extraVolumeClaimTemplates:
    - metadata:
        name: wal
      spec:
        accessModes: [ReadWriteOnce]
        resources:
          requests:
            storage: 10Gi
    - metadata:
        name: logs
      spec:
        accessModes: [ReadWriteOnce]
        resources:
          requests:
            storage: 5Gi

# Mount the extra claims (name must match each volumeClaimTemplate's metadata.name)
extraVolumeMounts:
  - name: wal
    mountPath: /var/lib/postgresql/wal
  - name: logs
    mountPath: /var/log/postgresql
```

> Each `volumeClaimTemplate` yields a per-replica PVC (`<name>-<pod>-N`). To define **only** custom claims (no default `data`), set `persistence.enabled: false` and list them all under `extraVolumeClaimTemplates`. Retention of these PVCs follows `persistence.persistentVolumeClaimRetentionPolicy` / Kubernetes defaults, same as the `data` claim.

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

### Maintaining the parameter docs

The tables in the [Parameters](#parameters) section are **auto-generated** from the
`## @param` / `## @section` annotations in `values.yaml` using
[readme-generator-for-helm](https://github.com/bitnami/readme-generator-for-helm).
Do not edit them by hand. After changing `values.yaml`, regenerate from the repo root:

```bash
make docs        # regenerate README parameter tables for all charts
make docs-check  # verify README is in sync (used in CI)
```

Annotation rules: every leaf value needs a `## @param <path> <description>` line;
use `[object]` / `[array]` modifiers for non-scalar values, `## @extra <path>` for
documented-but-commented options, and `## @section` to group a table.

## Chart Structure

```
generic-app/
├── Chart.yaml              # Chart metadata
├── CHANGELOG.md            # Release notes (also used as the GitHub release body)
├── values.yaml             # Default configuration values
├── values.schema.json      # JSON Schema for values.yaml
├── ci/                     # Render fixtures linted and validated in CI (not packaged)
├── tests/                  # helm-unittest suites (not packaged)
├── examples/               # Documented example values (not packaged)
├── templates/
│   ├── _helpers.tpl        # Template helpers
│   ├── _pod.tpl            # Pod template shared by all workload kinds
│   ├── deployment.yaml     # Deployment resource
│   ├── statefulset.yaml    # StatefulSet resource
│   ├── daemonset.yaml      # DaemonSet resource
│   ├── service.yaml        # Service resource
│   ├── service-headless.yaml  # Headless service for StatefulSet
│   ├── ingress.yaml        # Ingress resource
│   ├── httproute.yaml      # Gateway API HTTPRoute
│   ├── gatewayapi-http-redirect.yaml  # Optional HTTP -> HTTPS redirect HTTPRoute
│   ├── gatewayapi-certificate.yaml  # cert-manager Certificate (Gateway TLS secret)
│   ├── gatewayapi-ngf-clientsettingspolicy.yaml  # NGINX Gateway Fabric ClientSettingsPolicy
│   ├── gatewayapi-ngf-snippetsfilter.yaml  # NGINX Gateway Fabric SnippetsFilter
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
│   ├── servicemonitor.yaml # Prometheus Operator ServiceMonitor
│   ├── extra-deploy.yaml   # Extra Kubernetes objects
│   └── NOTES.txt           # Installation notes
└── README.md               # This file
```

## Upgrading

### To 2.0.0

2.0.0 removes the chart's implicit defaults (image, Service port 80) and fixes several
rendering bugs. Most configurations need one or two value changes:

- Set `image.repository` and `image.tag` explicitly.
- Set `service.enabled: true` and declare `service.ports` if you relied on the default `http: 80`.
- Set `serviceAccount.automountServiceAccountToken: true` if the app calls the Kubernetes API.
- **StatefulSet with persistence**: the `volumeClaimTemplates` labels changed, and that field
  is immutable. Delete the StatefulSet object while keeping its pods and PVCs, then upgrade:
  `kubectl delete statefulset <name> --cascade=orphan`.

The full list, with the reason for each change, is in the [CHANGELOG](./CHANGELOG.md#200---2026-10-22).

### Commands

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

**Issue**: `values don't meet the specifications of the schema(s)`

- The message names the offending path. An "additional properties ... not allowed" error is
  usually a typo (e.g. `service.port` instead of `service.ports`); values your own templates
  read belong under `extraValues`

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
    targetRevision: 2.0.0
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
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: quyendv
spec:
  interval: 10m
  url: https://quyendv.github.io/helm-charts
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: my-app
spec:
  chart:
    spec:
      chart: generic-app
      version: 2.0.0
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
- [Gateway API HTTP Redirect Example](./examples/values-gateway-api-redirect-example.yaml) - main HTTPS route plus HTTPRoute `RequestRedirect` for HTTP → HTTPS
- [Gateway API + NGINX Gateway Fabric](./examples/values-gateway-api-ngf-example.yaml) - optional `ClientSettingsPolicy` and `SnippetsFilter` presets (single HTTPRoute)

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Bitnami Charts](https://github.com/bitnami/charts)
