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
| [generic-app](./charts/generic-app) | A generic Helm chart that can be used for various applications | 1.9.2 |
<!-- CHARTS_TABLE:END -->

## Development

```bash
# Lint all charts
make lint

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
- **This root README** is just an index. Its chart table is generated from `Chart.yaml`, and `index.html` (the GitHub Pages landing page) reads the live version from the published `index.yaml`. So versions and the chart list stay in sync automatically — edit `values.yaml`/`Chart.yaml`, then run `make docs`.

## Contributing

1. Branch off `develop`.
2. Make your changes, update `values.yaml` annotations / `Chart.yaml` as needed.
3. Run `make docs` and `make lint`, commit the result.
4. Open a pull request against `develop`.

### Adding a new chart

1. Create the chart under `charts/<chart-name>/`.
2. Fill in `Chart.yaml` (name, version, description) and document `values.yaml` with `## @param` annotations.
3. Run `make docs` — the chart is picked up automatically and added to the table above.
4. Submit a PR to `develop`.

## Automated releases

Pushing to `main` or `develop` (when `charts/**` changes) triggers [chart-releaser-action](https://github.com/helm/chart-releaser-action), which packages each chart, creates a GitHub release per chart version, updates the Helm repository `index.yaml`, and deploys `index.html` to GitHub Pages. Existing versions are skipped (`skip_existing`), so bump the chart `version` to publish a new release.

## License

[MIT License](LICENSE)

## Maintainers

- [@quyendv](https://github.com/quyendv)

## Support

- **Issues**: [GitHub Issues](https://github.com/quyendv/helm-charts/issues)
