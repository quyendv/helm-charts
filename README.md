# Helm Charts Repository

[![Release Charts](https://github.com/quyendv/helm-charts/actions/workflows/release.yml/badge.svg)](https://github.com/quyendv/helm-charts/actions/workflows/release.yml)

Production-ready Helm charts for Kubernetes deployments.

## Usage

### Add Helm Repository

```bash
helm repo add quyendv https://quyendv.github.io/helm-charts
helm repo update
```

### Search Available Charts

```bash
helm search repo quyendv
```

### Install a Chart

```bash
helm install my-release quyendv/<chart-name>
```

## Available Charts

| Chart                               | Description                                                | Version |
| ----------------------------------- | ---------------------------------------------------------- | ------- |
| [generic-app](./charts/generic-app) | Generic application chart for Deployments and StatefulSets | 1.0.0   |

## Charts

### generic-app

A comprehensive, production-ready Helm chart for deploying various applications to Kubernetes.

**Features:**

- Support for Deployment and StatefulSet
- Ingress with TLS
- ConfigMaps and Secrets
- Persistent Volume Claims
- HPA, PDB, Network Policy
- RBAC support

**Quick Install:**

```bash
helm install my-app quyendv/generic-app \
  --set image.repository=nginx \
  --set image.tag=latest \
  --set service.type=LoadBalancer
```

[View Documentation](./charts/generic-app/README.md)

## Development

### Prerequisites

- Helm 3.2.0+
- Kubernetes 1.19+ (for testing)

### Local Testing

```bash
# Lint charts
helm lint generic-app

# Template rendering
helm template my-app generic-app -f generic-app/values.yaml

# Dry-run installation
helm install my-app generic-app --dry-run --debug

# Install locally
helm install my-app ./generic-app
```

### Chart Structure

```
helm-charts/
├── .github/
│   └── workflows/
│       └── release.yml      # GitHub Actions for chart releases
├── generic-app/             # Chart directory
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   └── README.md
└── README.md               # This file
```

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-chart`
3. Commit your changes: `git commit -am 'Add new chart'`
4. Push to the branch: `git push origin feature/my-chart`
5. Submit a pull request

### Adding a New Chart

1. Create chart directory: `helm create <chart-name>`
2. Update `Chart.yaml` with proper metadata
3. Add comprehensive `README.md`
4. Test thoroughly
5. Submit PR to `develop` branch

## Automated Releases

Charts are automatically packaged and published to GitHub Pages when changes are pushed to `main` or `develop` branches using [chart-releaser-action](https://github.com/helm/chart-releaser-action).

The release process:

1. Packages all charts in the repository
2. Creates GitHub releases for each chart version
3. Updates the Helm repository index
4. Publishes to GitHub Pages

## License

[MIT License](LICENSE)

## Maintainers

- [@quyendv](https://github.com/quyendv)

## Support

- **Issues**: [GitHub Issues](https://github.com/quyendv/helm-charts/issues)
- **Documentation**: [Chart Documentation](./charts/generic-app/README.md)
