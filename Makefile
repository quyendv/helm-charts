# Helm charts repository tasks
#
# Documentation tables in each chart's README.md are auto-generated from the
# `## @param` / `## @section` annotations in values.yaml using Bitnami's
# readme-generator-for-helm. Edit values.yaml annotations, then run `make docs`.

CHARTS := $(wildcard charts/*)
README_GENERATOR := npx --yes @bitnami/readme-generator-for-helm

.PHONY: docs docs-check lint help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

docs: ## Regenerate README parameter tables from values.yaml annotations
	@for chart in $(CHARTS); do \
		if [ -f "$$chart/values.yaml" ] && [ -f "$$chart/README.md" ]; then \
			echo "==> Generating docs for $$chart"; \
			$(README_GENERATOR) -v "$$chart/values.yaml" -r "$$chart/README.md"; \
		fi; \
	done

docs-check: docs ## Fail if README is out of sync with values.yaml (CI)
	@if ! git diff --exit-code -- 'charts/*/README.md'; then \
		echo ""; \
		echo "ERROR: README parameter tables are out of date."; \
		echo "       Run 'make docs' and commit the result."; \
		exit 1; \
	fi
	@echo "Docs are up to date."

lint: ## Lint all charts
	@for chart in $(CHARTS); do \
		echo "==> Linting $$chart"; \
		helm lint "$$chart"; \
	done
