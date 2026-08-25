# Testing with Gluon

Big Bang packages use Helm tests to verify that an application is functional after deployment. Gluon is Big Bang's shared Helm library chart for rendering Cypress UI tests and script-based tests.

Use the [Gluon tags](https://repo1.dso.mil/big-bang/product/packages/gluon/-/tags) to select a released version. The [Gluon test documentation](https://repo1.dso.mil/big-bang/product/packages/gluon/-/blob/master/docs/bb-tests.md) is the source of truth for supported values and templates.

## Add the Gluon Dependency

Add Gluon to the package's `chart/Chart.yaml` and pin a released version:

```yaml
dependencies:
  - name: gluon
    version: "x.x.x"
    repository: oci://registry1.dso.mil/bigbang
```

Authenticate to Registry One when required, then vendor the dependency:

```shell
helm registry login registry1.dso.mil
helm dependency update chart
```

Commit the resulting chart archive so the package remains usable in an air-gapped environment.

## Configure Test Values

Keep tests disabled in the package's default `chart/values.yaml`:

```yaml
bbtests:
  enabled: false
  cypress:
    artifacts: true
    envs: {}
  scripts:
    envs: {}
```

Enable them in `tests/test-values.yaml`, which is supplied by package CI:

```yaml
bbtests:
  enabled: true
```

Environment variable names intended for Cypress must use the `cypress_` prefix. Gluon passes script-test variables from `bbtests.scripts.envs` and sensitive values from `bbtests.scripts.secretEnvs`.

## Add Cypress Tests

Render Gluon's Cypress Helm-test resources from a template such as `chart/templates/tests/cypress-test.yaml`:

```yaml
{{- include "gluon.tests.cypress-configmap.base" . }}
---
{{- include "gluon.tests.cypress-runner.base" . }}
```

Place Cypress tests in `chart/tests/cypress/e2e/` and name them `*.cy.js`. Store the package's Cypress dependencies in `chart/tests/package.json` and `chart/tests/package-lock.json`.

Use Gluon's [Cypress execution guide](https://repo1.dso.mil/big-bang/product/packages/gluon/-/blob/master/docs/executing-cypress.md) for current directory layout, local execution, and in-cluster execution instructions.

## Add Script Tests

Render Gluon's script Helm-test resources from a template such as `chart/templates/tests/script-test.yaml`:

```yaml
{{- include "gluon.tests.script-configmap.base" . }}
---
{{- include "gluon.tests.script-runner.base" . }}
```

Place executable test scripts in `chart/tests/scripts/`. Use `bbtests.scripts.image` when the scripts require a purpose-built CLI image, and request only the Kubernetes API permissions the tests need under `bbtests.scripts.permissions`.

## Run and Validate Tests

Install the package with its test values, then run the Helm tests against the release:

```shell
helm test RELEASE_NAME --namespace PACKAGE_NAMESPACE
```

The current Big Bang package pipeline installs the package and runs these Helm tests automatically. When Cypress artifacts are enabled, screenshots and videos are collected by the pipeline according to its artifact-storage configuration.

## Generate Package README Files

Gluon also owns the standard templates and workflow for generating package README files. Follow the [Gluon package README documentation](https://repo1.dso.mil/big-bang/product/packages/gluon/-/blob/master/docs/bb-package-readme.md) instead of copying those commands into Big Bang documentation.
