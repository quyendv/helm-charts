# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
