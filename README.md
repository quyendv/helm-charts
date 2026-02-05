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

- Support for **Deployment** and **StatefulSet**
- **Ingress** with TLS and cert-manager support
- **Multiple ConfigMaps/Secrets** for environment variables
- **Persistent Volume Claims** with flexible mounting
- **Pod Affinity/Anti-Affinity** for HA deployments
- **HPA, PDB, Network Policy**
- **RBAC** with ServiceAccount and custom roles
- **Health Probes** (Liveness, Readiness, Startup)
- **Init Containers** and **Sidecars** support
- **Security Context** configuration

**Quick Install:**

```bash
helm install my-app quyendv/generic-app \
  --set image.repository=nginx \
  --set image.tag=1.25.3 \
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
helm lint charts/generic-app

# Template rendering
helm template my-app charts/generic-app -f charts/generic-app/values.yaml

# Dry-run installation
helm install my-app charts/generic-app --dry-run --debug

# Install locally
helm install my-app ./charts/generic-app

# Test with examples
helm template my-app charts/generic-app \
  -f charts/generic-app/examples/values-microservice-example.yaml
```

### Chart Structure

```
helm-charts/
├── .github/
│   └── workflows/
│       └── release.yml           # GitHub Actions for chart releases
├── charts/
│   └── generic-app/              # Chart directory
│       ├── Chart.yaml            # Chart metadata
│       ├── values.yaml           # Default values
│       ├── README.md             # Chart documentation
│       ├── CHANGELOG.md          # Version history
│       ├── MIGRATION.md          # Migration guide
│       ├── templates/            # Kubernetes manifests
│       │   ├── _helpers.tpl
│       │   ├── deployment.yaml
│       │   ├── statefulset.yaml
│       │   ├── service.yaml
│       │   ├── ingress.yaml
│       │   └── ...
│       ├── docs/                 # Additional documentation
│       └── examples/             # Example values files
│           ├── values-microservice-example.yaml
│           ├── values-affinity-example.yaml
│           └── ...
└── README.md                     # This file
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
