# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [1.4.0] - Previous Release

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
