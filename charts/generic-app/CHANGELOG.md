# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
