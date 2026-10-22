# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-10-22

2.0.0 removes the chart's implicit defaults, fixes a set of rendering bugs and adds a values schema. Read **Upgrading from 1.x** before upgrading.

### Upgrading from 1.x

1. **Set the image explicitly.** There is no default image any more: `image.repository` and `image.tag` (or `image.digest`) are required.
2. **Declare the Service if you used the default one.** `service.enabled` now defaults to `false` and `service.ports` to `{}`. Releases that relied on the default `http: 80` must set:

   ```yaml
   service:
     enabled: true
     ports:
       http: 80
   ```

   If you removed the old default with `service.ports.http: null`, you can drop that line.
3. **Re-enable the API token if the app uses it.** `serviceAccount.automountServiceAccountToken` defaults to `false` and now also applies to the pod. Set it to `true` when the app talks to the Kubernetes API (for example together with `rbac.create`).
4. **StatefulSet with persistence: recreate the StatefulSet object.** The `volumeClaimTemplates` labels changed (see Fixed) and Kubernetes does not allow that field to change in place. Delete the StatefulSet without touching its pods or PVCs, then upgrade. The upgrade adopts the running pods and the existing claims:

   ```bash
   kubectl delete statefulset <release-fullname> --cascade=orphan
   helm upgrade <release> quyendv/generic-app --version 2.0.0 -f values.yaml
   ```

5. **Ingress:** `ingress.apiVersion` is gone (only `networking.k8s.io/v1` is rendered), `ingress.hostname` defaults to `""` and `ingress.pathType` to `Prefix`. Set `pathType: ImplementationSpecific` to keep the old matching behaviour.
6. **Custom top-level keys** read by your own templates (`extraDeploy`, tpl-enabled fields) must move under `extraValues`: the schema rejects unknown top-level keys.
7. Expect one rollout: pods now carry `commonLabels`, no longer render empty `annotations`/`affinity`/`env`/`volumes` keys, and set `automountServiceAccountToken`.

### Changed

- **No default image.** The chart shipped `docker.io/nginx:1.25.3`, which no real release wants and which hid a missing `image.*` value behind a working-looking deploy. Rendering now fails with a clear message. `image.registry` and `image.pullPolicy` default to empty, leaving both to the Kubernetes defaults.
- **No default Service port.** The `service.ports.http: 80` default merged into every user's map, so a chart that only wanted `grpc: 9000` also got `http: 80`, and the pod declared `containerPort: 80` even when the app listened elsewhere. `service.ports` and `service.nodePorts` are now empty, `service.enabled` defaults to `false`, and enabling the Service without a port fails. This follows bjw-s app-template, the most widely used generic chart; Bitnami charts can ship a default only because each one knows its application's port.
- **Ingress, HTTPRoute and NOTES no longer assume a port named `http`.** Ingress and HTTPRoute route to the new `ingress.servicePort` / `gatewayApi.httpRoute.servicePort` when set, else to `http`, else to the only Service port (named `service.extraPorts` entries included, null entries ignored); ambiguity is an error, not an empty `port:`. The Ingress backend references the port by name. NOTES, being informational, shows `http` or else the first port by name.
- **Ingress renders `networking.k8s.io/v1` only.** The pre-1.19 API branches are removed together with `ingress.apiVersion`. `ingress.hostname` defaults to `""` (was `app.local`) and `ingress.pathType` to `Prefix`, which every controller implements the same way.
- **`serviceAccount.automountServiceAccountToken` defaults to `false`** and is also set on the pod spec, so it applies even when the pod uses an existing ServiceAccount. A mounted token is a credential most applications never need.
- **The StatefulSet headless Service always exists** for `kind: StatefulSet`, independent of `service.enabled`, because `spec.serviceName` must point at a real Service. Its ports are the container ports.
- **Pods carry `commonLabels`**, and labels and annotations are now merged rather than concatenated: a key set in two places is emitted once instead of producing YAML with duplicate keys. Selector labels always win.
- **`affinity` and `topologySpreadConstraints` are rendered through `tpl`**, like the other pod-level fields.
- `resources` defaults to `{}` instead of empty `limits`/`requests` maps.

### Added

- **`values.schema.json`**: unknown keys and invalid values fail at install time with the offending path, on Helm 3 and Helm 4. Chart-owned objects are closed; fields passed through to Kubernetes stay open. Label and annotation values must be strings (an unquoted `8080` or `true` is caught here rather than by the API server). A root-level `enabled` key is allowed so parent charts can gate this one with `condition: <name>.enabled`.
- **`extraValues`**: free-form values for your own templates.
- **`image.digest`**: pin the image by digest, alone or together with a tag.
- **`ingress.servicePort`** and **`gatewayApi.httpRoute.servicePort`**.
- **Fail-fast checks** for configurations that previously rendered broken objects: Ingress or ServiceMonitor without the Service, Ingress TLS without a hostname, an Ingress with no rules, `secrets` and `externalSecret` writing the same Secret, and `rbac.create` binding a Role to the namespace's `default` ServiceAccount.
- **Warnings** for NGF snippets that cannot attach to user-supplied HTTPRoute rules, a `ReadWriteOnce` claim shared by pods that may land on different nodes, an RBAC Role with no token mounted, and rolling image tags (the old check never fired with the default pull policy).

### Fixed

- **Every chart upgrade failed on a StatefulSet with persistence.** The `data` volumeClaimTemplate carried the full label set, including `helm.sh/chart: generic-app-<version>`, and `volumeClaimTemplates` is immutable. It now carries only the selector labels.
- **NetworkPolicy allowed the wrong ports.** With `allowExternal: false` it opened the Service ports, but NetworkPolicy matches pod ports: Service 80 → container 8080 blocked all traffic. It now uses the container ports.
- **DaemonSet with `persistence.enabled` referenced a PVC that was never created**, leaving pods Pending. The chart now creates it for every kind except StatefulSet.
- **PodDisruptionBudget was rejected when `maxUnavailable` was set**, because the `minAvailable: 1` default was rendered next to it. `maxUnavailable` now takes precedence, and `0` is accepted for both.
- **ServiceMonitor scraped StatefulSet pods twice**: it selected the headless Service as well, which carries the same labels. The headless Service is now labelled `generic-app/headless: "true"` and excluded.
- **`secrets.data` values that YAML parses as numbers or booleans** (`PORT: 5432`) failed to render. Large numbers are stored as written (`123456789012`, not `1.23456789012e+11`).
- **An unquoted numeric `image.tag` in a values file** (`tag: 20240101`) rendered as `2.0240101e+07`. Whole numbers are now formatted exactly; a decimal such as `1.10` is rejected by the schema, since it has already become `1.1` when parsed and must be quoted.
- **The HTTP → HTTPS redirect route skipped `gatewayApi.hostname`** whenever `gatewayApi.httpRoute.hostnames` was also set. Route, redirect and Certificate now share one hostname list.
- `terminationGracePeriodSeconds: 0` was ignored.
- The StatefulSet now honours `minReadySeconds`, and `persistentVolumeClaimRetentionPolicy` also applies when only `extraVolumeClaimTemplates` are used.
- The headless Service name is truncated to stay within 63 characters.
- NOTES printed port-forward instructions for a Service that did not exist.
- `examples/values-extra-deploy-example.yaml` did not render; the README `extraDeploy` example was not valid YAML.

### Internal

- Deployment, StatefulSet and DaemonSet share one pod template (`_pod.tpl`) instead of three diverging copies.
- CI lints, renders and validates every `ci/` and `examples/` values file with kubeconform (Kubernetes and CRD schemas) and runs helm-unittest suites, on Helm 3 and Helm 4.
- GitHub releases now carry the matching CHANGELOG section instead of the chart description.

## [1.15.0] - 2026-09-09

### Changed

- **`HTTPRoute` backend references now render the Gateway API schema defaults explicitly** (`group: ""`, `kind: Service`, `weight: 1`). The API server fills these in on the stored object, so a manifest that omitted them never matched what was running: any tool that diffs the desired manifest against the live resource reported every `HTTPRoute` produced by this chart as permanently drifted, drowning real drift in noise. This is a no-op semantically -- the rendered route resolves to exactly the same backend -- but it does change the rendered YAML, so a diff against a previous render will show the three added fields.

  Suppressing the noise on the consumer side is the worse option and is why this belongs in the chart: an ignore rule has to point inside an array element (`.spec.rules[].backendRefs[]`), and an ignore rule scoped that way can also mask genuine changes to the sibling fields of that same element, including `name` and `port`.

## [1.14.0] - 2026-09-08

### Added

- **`externalSecret.name`**: name the generated `ExternalSecret` object independently of the chart fullname (empty keeps the previous behaviour, so rendering is unchanged for existing users). Previously only `externalSecret.target.name` -- the Secret produced -- was configurable, while the resource itself was locked to the fullname. That made the native integration unusable for adopting an `ExternalSecret` that already exists under a different name, a common case when migrating one off `extraDeploy` or when the secret is named after what it contains rather than after the app.

## [1.13.0] - 2026-08-08

### Changed

- **`containerPorts` fallback is now scoped to `service.enabled`.** When `containerPorts` is empty the pod still mirrors `service.ports`, but only while the Service is enabled. Previously a service-less workload (worker, consumer, cron — `service.enabled: false`) inherited the chart's default `service.ports.http: 80` and rendered a meaningless `containerPort: 80`, which could only be suppressed with the `service.ports.http: null` merge trick. Rendering is unchanged for every chart user with `service.enabled: true`; workloads with the Service disabled and no explicit `containerPorts` lose their spurious port entry (a pod-template change, so expect one rollout on upgrade).

### Added

- **Service port name validation**: warns when `service.ports` contains a name that `containerPorts` does not declare. The Service targets ports by **name**, so such a mismatch silently produces a Service that never routes to the pod — the most common way an explicit `containerPorts` map breaks traffic.

## [1.12.0] - 2026-07-12

### Added

- **`persistence.extraVolumeClaimTemplates`**: append additional `volumeClaimTemplates` to a StatefulSet beyond the single default `data` claim. Each entry is a raw PVC template (rendered via `tplvalues.render`); mount them via `extraVolumeMounts` (name must match `metadata.name`). Backward compatible (empty by default); set `persistence.enabled=false` to define all claims here instead of the default `data` one.

## [1.11.0] - 2026-07-06

### Added

- **`gatewayApi.httpRoute.timeouts`**: set Gateway API HTTPRoute rule timeouts (`request` / `backendRequest`) on the generated default rule without having to override the whole `rules` block. Applies only when `rules` is empty (same scoping as `httpRoute.path`); when you author full `rules`, put `timeouts` per-rule yourself. Rendered via `tplvalues.render`.

## [1.10.0] - 2026-06-30

### Added

- **`ExternalSecret` integration** (`externalSecret.*`): first-class support for the External Secrets Operator, alongside the existing cert-manager / Gateway API / ServiceMonitor integrations. Set `externalSecret.enabled=true` to create an `ExternalSecret` that materializes a Secret (named after the chart by default) which the app can consume via `extraEnvVarsSecrets`. Configurable: `apiVersion` (override for older operator releases), `refreshInterval`, `secretStoreRef`, `target` (name/creationPolicy/deletionPolicy/template), `data`, `dataFrom`, `annotations`, `labels`. A validation warning fires when enabled without a store reference or without any data. For advanced cases (multiple ExternalSecrets, PushSecret, generators) keep using `extraDeploy`.

## [1.9.2] - 2026-06-27

### Added

- **`persistence.resourcePolicy`** (default `keep`): the chart-managed PVC for `kind: Deployment` now carries `helm.sh/resource-policy: keep`, so `helm uninstall` no longer destroys its data. Set to `""` to restore the previous delete-on-uninstall behavior.
- **`persistence.persistentVolumeClaimRetentionPolicy`**: expose the StatefulSet PVC retention policy (Kubernetes 1.27+) so `volumeClaimTemplates` PVCs can optionally be garbage-collected on scale-down/delete. Defaults to Kubernetes' Retain behavior.

### Changed

- **PVC retention is now safe and consistent by default.** Previously a Deployment's PVC was deleted on uninstall while a StatefulSet's PVCs were retained — an asymmetry that could cause accidental data loss. Both now retain data by default; deletion is opt-in. Documented under "Uninstalling the Chart".

## [1.9.1] - 2026-06-25

### Fixed

- **`extraEnvVarsConfigMaps` / `extraEnvVarsSecrets` template evaluation**: The `envFrom` names were rendered via raw `{{ . }}`, so quoted template expressions (e.g. `'{{ include "generic-app.fullname" . }}'`) were emitted verbatim and produced invalid YAML (`invalid map key`), breaking `helm install`. This also caused the bundled `examples/values-stateful-example.yaml` to fail rendering. Names are now rendered via `tplvalues.render` in Deployment, StatefulSet, and DaemonSet — dynamic names work while literal names remain unchanged.

## [1.9.0] - 2026-06-13

### Added

- **`containerPorts`**: Optional map to declare container ports independently of `service.ports`. Falls back to `service.ports` when not set (backward compatible).
- **`DaemonSet` workload kind**: `kind: DaemonSet` is now supported. Supports `updateStrategy`, `minReadySeconds`, and all pod-level options. HPA is suppressed for DaemonSet with a validation warning.
- **`minReadySeconds`**: New parameter that applies to Deployment and DaemonSet workloads.
- **`ServiceMonitor` template**: Built-in Prometheus Operator integration via `serviceMonitor.enabled`. Configurable fields: `port`, `path`, `interval`, `scrapeTimeout`, `scheme`, `honorLabels`, `jobLabel`, `labels`, `annotations`, `relabelings`, `metricRelabelings`. Includes port validation warning.

### Fixed

- **StatefulSet spurious `emptyDir` volume**: A `data` volume with `emptyDir` was created when `persistence.enabled: false` even though no container mounted it. The volume is no longer created when persistence is disabled.
- **`gatewayApi.httpRoute.rules` template evaluation**: Rules were rendered via `toYaml` which does not evaluate Helm template expressions. Now rendered via `tplvalues.render` — quoted template expressions in string fields (Style 2) and block-string rules (Style 3) are fully evaluated.

## [1.8.0] - 2026-04-26

### Added

- **NGINX Gateway Fabric (optional)**: `gatewayApi.nginxGatewayFabric` presets for the chart-managed single `HTTPRoute`
  - Optional `ClientSettingsPolicy` for `client_max_body_size` via `clientSettings.bodyMaxSize`
  - Optional shared `SnippetsFilter` (stable name `*-ngf-snippets`) with Ingress-like `proxy_*_timeout` directives from `upstreamProxyTimeouts` and optional `snippets.extra` list entries
  - Single `ExtensionRef` on the generated default `HTTPRoute` rule when snippets are used; no auto-injection when `gatewayApi.httpRoute.rules` is non-empty (documented)
- Example: `examples/values-gateway-api-ngf-example.yaml`
- Template guard: `gatewayApi.nginxGatewayFabric.enabled` requires `gatewayApi.enabled`
- **Gateway API redirect option**: `gatewayApi.httpRedirect` can create an additional redirect-only `HTTPRoute` (`RequestRedirect`) to enforce HTTP -> HTTPS without defining redirect rules per app route
- Example: `examples/values-gateway-api-redirect-example.yaml`

## [1.7.0] - 2026-04-23

### Added

- **Gateway API**: Optional `HTTPRoute` and cert-manager `Certificate` via `gatewayApi` values
  - Aligns with common production split: platform owns `Gateway` / `GatewayClass`; app chart attaches routes with `parentRefs`
  - Documented ACME `gatewayHTTPRoute` solver example under `certManager.acme.solvers` for HTTP-01 with Gateway API
- Example: `examples/values-gateway-api-example.yaml`

## [1.6.1] - 2026-02-24

### Fixed

- **Checksum annotation logic**: Removed references to non-existent `extraEnvVarsCM` and `extraEnvVarsSecret` keys in `_helpers.tpl`
  - Previous conditions `(not .Values.extraEnvVarsCM)` and `(not .Values.extraEnvVarsSecret)` always evaluated to `true` because these keys didn't exist in `values.yaml` (refactored to `extraEnvVarsConfigMaps` / `extraEnvVarsSecrets` arrays)
  - Simplified checksum conditions to `configMaps.enabled` / `secrets.enabled` only — matching the standard pattern used by major Helm charts (Bitnami, etc.)
- **Example files**: Fixed `values-microservice-example.yaml` and `values-stateful-example.yaml` to use correct keys (`extraEnvVarsSecrets` array instead of deprecated singular `extraEnvVarsSecret` string)

## [1.6.0] - 2026-02-12

### Added

- **extraDeploy** feature: Deploy additional Kubernetes resources alongside your application
  - Full Helm templating support for all extra objects
  - Can deploy any Kubernetes resource type (ConfigMap, Secret, Job, CronJob, ServiceMonitor, etc.)
  - Automatically inherits namespace, labels, and annotations from chart
  - New template file `templates/extra-deploy.yaml` to handle extra deployments
- New example file `examples/values-extra-deploy-example.yaml` with practical use cases:
  - Nginx configuration ConfigMap
  - Database migration Job
  - Backup CronJob
  - Prometheus ServiceMonitor
  - Custom application Secret
  - Init database Job
- Enhanced documentation in README.md with extraDeploy parameters and examples

### Changed

- Updated `values.yaml` with comprehensive extraDeploy documentation and examples
- Updated README.md with new "Extra Deploy Parameters" section
- Updated README.md with Example 8 demonstrating extraDeploy usage

## [1.5.0] - 2026-02-11

### Added

- Support for configuring rolling update strategy options:
  - `updateStrategy.rollingUpdate.maxSurge` - Maximum number of pods that can be created over desired replicas (Deployment only)
  - `updateStrategy.rollingUpdate.maxUnavailable` - Maximum number of pods that can be unavailable during update
  - `updateStrategy.rollingUpdate.partition` - Ordinal at which StatefulSet should be partitioned for controlled rollout (StatefulSet only)
- New example file `examples/values-rolling-update-example.yaml` with 7 different update strategy patterns:
  - Zero-downtime deployment
  - Fast rolling update
  - Percentage-based rolling update
  - Recreate strategy
  - StatefulSet controlled rollout (canary-style)
  - StatefulSet with OnDelete strategy
  - Conservative rolling update
- Enhanced documentation in README.md with update strategy parameters and examples

### Changed

- Updated README.md with new "Update Strategy Parameters" section
- Updated README.md with Example 6 demonstrating zero-downtime deployment configuration
- Reorganized examples section in README.md

## [1.4.0] - 2026-02-06

### Added

- **cert-manager integration**: optional `Issuer`/`ClusterIssuer` (ACME, CA or Vault) managed by the chart (`certManager.*`).

### Features at this release

### Features

- Support for both Deployment and StatefulSet workloads
- Flexible Service configuration
- Ingress with TLS support
- Cert-manager integration for automatic SSL/TLS certificates
- ConfigMaps and Secrets management
- Persistent Volume Claims
- ServiceAccount and RBAC configuration
- Horizontal Pod Autoscaling
- Pod Disruption Budget
- Network Policy
- Security Context configuration
- Health probes (Liveness, Readiness, Startup)
- Affinity and Anti-Affinity rules
- Init containers and Sidecars support
- Extra volumes and volume mounts

## [1.3.1] - 2026-02-05

### Changed

- **Security contexts are disabled by default.** `containerSecurityContext` and `podSecurityContext` now default to `enabled: false` (previously `runAsUser: 1001`, `runAsNonRoot: true` and `fsGroup: 1001`); the hardened settings remain as commented examples.
- README rewritten with parameter documentation and usage examples.

## [1.3.0] - 2026-02-05

### Added

- **Affinity presets**: `podAffinityPreset`, `podAntiAffinityPreset` (`soft` / `hard`) and `nodeAffinityPreset`, plus `examples/values-affinity-example.yaml`.
- **`extraEnvVarsConfigMaps` / `extraEnvVarsSecrets`**: load several ConfigMaps and Secrets as environment variables.

### Changed

- **Breaking:** `extraEnvVarsCM` and `extraEnvVarsSecret` (single name) are replaced by the list-valued `extraEnvVarsConfigMaps` and `extraEnvVarsSecrets`.
- `podAntiAffinityPreset` defaults to `""` (no anti-affinity) instead of `soft`.

### Removed

- `ingress.selfSigned` and `ingress.secrets` (self-signed or user-supplied TLS certificates rendered by the chart).
- `extraDeploy` (reintroduced in 1.6.0).

## [1.1.0] - 2026-01-20

### Changed

- Liveness and readiness probes are disabled by default (`livenessProbe.enabled` / `readinessProbe.enabled: false`).

## [1.0.1] - 2026-01-05

### Added

- **`service.enabled`** (default `true`): skip the Service, and the StatefulSet headless Service, for workloads that expose no port.

## [1.0.0] - 2025-12-31

### Added

- Initial release: Deployment or StatefulSet (with headless Service), Service, Ingress, ConfigMap, Secret, PersistentVolumeClaim, ServiceAccount, Role/RoleBinding, HorizontalPodAutoscaler, PodDisruptionBudget and NetworkPolicy.
