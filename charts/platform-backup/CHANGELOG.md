# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-22

First release: one scheduled backup of one data store per release, running the
[platform-backup](https://github.com/quyendv/platform-backup) images (appVersion 0.6.0).

### Added

- **A `CronJob` per release** for PostgreSQL, MongoDB, Redis or SQLite. The image is
  `<image.registry>/<engine>:<tag>[-<variant>]`, the tag defaulting to the chart appVersion.
  Each run is a fresh pod with a size-limited `emptyDir` at `/backup`; `concurrencyPolicy:
  Forbid`, `restartPolicy: Never`, a run deadline and a TTL for finished Jobs by default.
- **The image's environment contract as values**: `s3.prefix` (`S3_PREFIX`), `keepLocal`,
  `s3.keepRemote` (`KEEP_REMOTE`; `0` renders as `"0"` and disables pruning),
  `verifyReadback` (`VERIFY_READBACK`) and `host` (`BACKUP_HOST`). Everything else goes in
  `env` (a sorted map) or `extraEnv`; redefining a chart-managed variable there fails.
- **S3 and target Secrets** from an existing Secret or an `external-secrets.io/v1`
  ExternalSecret (`<fullname>-s3` mapped property by property, `<fullname>-target` passing
  `data`, `dataFrom` and `template` through), both with `deletionPolicy: Retain`.
- **File stores** (`fileStore`): mounts the application's PersistentVolumeClaim and adds a
  required `podAffinity` term on the owner pod's labels, merged with any user `affinity`.
- **Fail-fast validation**: `schedule`, `s3.prefix`, `s3.keepRemote` and an S3 Secret source
  are required; each Secret takes exactly one source; `fileStore` needs `claimName` and
  `ownerSelector`; the fullname must contain `backup` (monitoring commonly selects backup
  CronJobs by name) and fit the 52-character CronJob limit.
- **`values.schema.json`**: `engine` is limited to the four supported backends, retention
  counts must be non-negative integers, and unknown keys fail at install time.
