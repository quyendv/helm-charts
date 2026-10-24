# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-10-24

### Changed

- `appVersion` is 0.8.0, so the image tag defaults to platform-backup 0.8.0:
  PostgreSQL images for 15-18 (pg14 dropped, PostgreSQL 14 being end of life
  on 2026-11-12). `image.variant` takes `pg15` .. `pg18`; match it to the
  server, for restore as much as for backup. Releases that set `image.tag` are
  unaffected.
- `engine: postgresql` with `image.variant: pg14` and no `image.tag` now fails
  to render instead of pointing the CronJob at an image that does not exist.
  Use `pg15`, which also backs up and restores a 14 server, or pin
  `image.tag: "0.7.0"`.

## [0.2.0] - 2026-10-24

### Added

- `engine: files`: back up a directory on the application's volume with the
  platform-backup files image. `files.include`, `files.exclude`, `files.require`
  and `files.forbid` become `FILES_INCLUDE`, `FILES_EXCLUDE`, `FILES_REQUIRE` and
  `FILES_FORBID`, one entry per line; `FILES_ROOT` is `fileStore.mountPath` plus
  `files.subPath`. The engine requires `fileStore`, and the chart refuses
  `FILES_*` in `env`/`extraEnv`. Example: `examples/values-files-example.yaml`.

### Changed

- `appVersion` is 0.7.0, so the image tag defaults to platform-backup 0.7.0:
  every image rebuilt on current bases and tools, with no fixable HIGH or
  CRITICAL CVE left outside MongoDB's own tool binaries. Releases that set
  `image.tag` are unaffected.

## [0.1.1] - 2026-10-22

### Changed

- `appVersion` is 0.6.3, so the image tag defaults to platform-backup 0.6.3.
  0.6.0 failed to verify PostgreSQL dumps larger than a pipe buffer, and 0.6.1
  could not download from some S3-compatible providers; releases that set
  `image.tag` are unaffected.

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
