# Helm Charts Repository

[![Release Charts](https://github.com/quyendv/helm-charts/actions/workflows/release.yml/badge.svg)](https://github.com/quyendv/helm-charts/actions/workflows/release.yml)

Production-ready Helm charts for Kubernetes deployments.

## Usage

```bash
# Add the repository
helm repo add quyendv https://quyendv.github.io/helm-charts
helm repo update

# Discover charts
helm search repo quyendv

# Install a chart
helm install my-release quyendv/<chart-name>
```

## Available Charts

> The table below is auto-generated from each chart's `Chart.yaml` by `make docs`. Do not edit by hand. Click a chart for its full documentation, parameters and examples.

<!-- CHARTS_TABLE:START -->
| Chart | Description | Version |
| ----- | ----------- | ------- |
| [generic-app](./charts/generic-app) | A generic Helm chart that can be used for various applications | 2.0.0 |
| [platform-backup](./charts/platform-backup) | A scheduled backup of one PostgreSQL, MongoDB, Redis or SQLite store, or a directory, to S3-compatible storage | 0.2.0 |
<!-- CHARTS_TABLE:END -->

## Development

```bash
# Lint all charts
make lint

# Lint + helm-unittest + kubeconform over every ci/ and examples/ values file (what CI runs)
make test

# Regenerate docs (chart parameter tables + the table above)
make docs

# Fail if docs are out of date (what CI runs)
make docs-check

# Render / dry-run a chart locally
helm template my-app charts/generic-app -f charts/generic-app/examples/values-webapp-example.yaml
helm install my-app ./charts/generic-app --dry-run=client --debug
```

Run `make help` to list available tasks.

### Documentation model

- **Per-chart docs live in the chart directory** (`charts/<name>/README.md`). Parameter tables there are generated from the `## @param` annotations in `values.yaml` via [readme-generator-for-helm](https://github.com/bitnami/readme-generator-for-helm).
- **This root README** is just an index. Its chart table is generated from `Chart.yaml`, and `index.html` (the GitHub Pages landing page) renders every chart, its latest version, description and keywords from the published `index.yaml`. So versions and the chart list stay in sync automatically — edit `values.yaml`/`Chart.yaml`, then run `make docs`. The static chart list in `index.html` is only a fallback for when `index.yaml` cannot be read.

## Contributing

`main` is the only long-lived branch.

1. Branch off `main`.
2. Make your changes, keeping `values.yaml` annotations and `values.schema.json` in step.
3. If the chart's packaged files changed, bump `version` in `Chart.yaml` (SemVer) and add a matching `## [x.y.z]` section to the chart's `CHANGELOG.md`. CI enforces both; changes limited to `README.md`, `CHANGELOG.md`, `examples/`, `ci/` and `tests/` are exempt.
4. Run `make docs` and `make test` (needs [helm-unittest](https://github.com/helm-unittest/helm-unittest) and [kubeconform](https://github.com/yannh/kubeconform)), and commit the result.
5. Open a pull request against `main`. To batch several changes into one release, collect them on a branch such as `release/x.y.z` and open a single PR.

### Adding a new chart

1. Create the chart under `charts/<chart-name>/`.
2. Fill in `Chart.yaml` (name, version, description), document `values.yaml` with `## @param` annotations and start a `CHANGELOG.md`.
3. Add render fixtures under `ci/` (they are linted and validated in CI) and, ideally, `tests/` for helm-unittest.
4. Run `make docs` — the chart is picked up automatically and added to the table above.
5. Submit a PR to `main`.

## Automated releases

Merging to `main` (when `charts/**` or `index.html` changes) triggers [chart-releaser-action](https://github.com/helm/chart-releaser-action). It packages each chart, creates a GitHub release and the `<chart>-<version>` tag for every new chart version, updates the Helm repository `index.yaml`, and deploys `index.html` to GitHub Pages. Existing versions are skipped (`skip_existing`), so the `version` in `Chart.yaml` is what triggers a release; do not create tags by hand.

The release body is that version's section of the chart's `CHANGELOG.md` (see `scripts/release-notes.sh`), followed by install instructions and a link to the diff against the previous release. `scripts/backfill-release-notes.sh` applies the same format to existing releases.

## License

[MIT License](LICENSE)

## Maintainers

- [@quyendv](https://github.com/quyendv)

## Support

- **Issues**: [GitHub Issues](https://github.com/quyendv/helm-charts/issues)
