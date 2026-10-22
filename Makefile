# Helm charts repository tasks
#
# Documentation tables in each chart's README.md are auto-generated from the
# `## @param` / `## @section` annotations in values.yaml using Bitnami's
# readme-generator-for-helm. The root README "Available Charts" table is
# generated from each Chart.yaml. Edit values.yaml/Chart.yaml, then `make docs`.

CHARTS := $(wildcard charts/*)
README_GENERATOR := npx --yes @bitnami/readme-generator-for-helm@2.7.2
KUBE_VERSION ?= 1.30.0
CRD_SCHEMAS := https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json
BASE_REF ?= origin/main

.PHONY: docs charts-index docs-check lint unittest kubeconform version-check test help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

docs: charts-index ## Regenerate all docs (chart parameter tables + root chart table)
	@for chart in $(CHARTS); do \
		if [ -f "$$chart/values.yaml" ] && [ -f "$$chart/README.md" ]; then \
			echo "==> Generating docs for $$chart"; \
			$(README_GENERATOR) -v "$$chart/values.yaml" -r "$$chart/README.md"; \
		fi; \
	done

charts-index: ## Regenerate the Available Charts table in the root README
	@echo "==> Generating root Available Charts table"
	@./scripts/gen-charts-index.sh

docs-check: docs ## Fail if README is out of sync with values.yaml/Chart.yaml (CI)
	@if ! git diff --exit-code -- 'charts/*/README.md' README.md; then \
		echo ""; \
		echo "ERROR: Generated docs are out of date."; \
		echo "       Run 'make docs' and commit the result."; \
		exit 1; \
	fi
	@echo "Docs are up to date."

lint: ## Lint all charts with their default values and every ci/*.yaml
	@set -e; for chart in $(CHARTS); do \
		echo "==> Linting $$chart"; \
		helm lint "$$chart"; \
		for values in $$chart/ci/*.yaml; do \
			[ -f "$$values" ] || continue; \
			helm lint --strict "$$chart" -f "$$values"; \
		done; \
	done

unittest: ## Run helm-unittest suites (needs the helm-unittest plugin)
	@set -e; for chart in $(CHARTS); do \
		if [ -d "$$chart/tests" ]; then helm unittest "$$chart"; fi; \
	done

kubeconform: ## Render every ci/ and examples/ values file and validate it against the Kubernetes and CRD schemas
	@set -e; for chart in $(CHARTS); do \
		for values in $$chart/ci/*.yaml $$chart/examples/*.yaml; do \
			[ -f "$$values" ] || continue; \
			echo "==> $$values"; \
			helm template release "$$chart" -f "$$values" | kubeconform -strict -summary \
				-kubernetes-version $(KUBE_VERSION) \
				-schema-location default -schema-location '$(CRD_SCHEMAS)'; \
		done; \
	done

version-check: ## Fail when a changed chart lacks a version bump or CHANGELOG entry (BASE_REF=origin/main)
	@./scripts/check-chart-versions.sh $(BASE_REF)

test: lint unittest kubeconform ## Run every chart check
