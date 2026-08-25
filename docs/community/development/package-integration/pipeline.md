# Pipeline Integration

Big Bang's package pipeline validates, tests, packages, and releases package Helm charts through GitLab CI. The [Pipeline Templates repository](https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates) owns the implementation and is the source of truth for current jobs, variables, labels, and release behavior.

## Prerequisites

- A Big Bang package project containing its Helm chart
- A GitLab runner available to the project
- Registry One credentials for pulling OCI chart dependencies and hardened images
- Package test values under `tests/test-values.yaml`

## Configure GitLab CI

Include the current package pipeline from the package repository's `.gitlab-ci.yml`:

```yaml
include:
  - project: big-bang/pipeline-templates/pipeline-templates
    ref: master
    file: /pipelines/bigbang-package-v2.yaml
```

Pin `ref` to an approved tag or commit when the package requires a controlled pipeline upgrade. Use `master` only when the package intentionally follows the latest pipeline behavior.

The retired `bigbang-package.yaml`, `third-party.yaml`, and `sandbox.yaml` paths must not be used for new package configuration.

## Add Package Tests

Place deployment overrides in `tests/test-values.yaml`. Add Gluon-based Helm tests by following [Testing with Gluon](testing.md).

The pipeline performs configuration validation and package tests for merge requests. It also runs packaging and release stages for protected tags. Consult the current [package pipeline definition](https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates/-/blob/master/pipelines/bigbang-package-v2.yaml) before relying on a particular stage or job name.

## Develop the Pipeline Safely

When validating a pipeline-templates change, point both the include and `PIPELINE_REPO_BRANCH` at the development branch:

```yaml
include:
  - project: big-bang/pipeline-templates/pipeline-templates
    ref: MY_PIPELINE_BRANCH
    file: /pipelines/bigbang-package-v2.yaml

variables:
  PIPELINE_REPO_BRANCH: MY_PIPELINE_BRANCH
```

Do not leave a package pinned to a temporary pipeline branch after validation.

## Pipeline Controls

Prefer the current MR labels documented by pipeline-templates over legacy title keywords. Common controls include:

- `kind::docs` — skip package CI for documentation-only changes
- `disable-ci` — disable pipeline execution
- `skip-job-upgrade` — skip the upgrade test job
- `skip-job-chartupdatecheck` — skip chart-version update validation
- `test-ci::release` — exercise package and release stages without publishing a normal release

Review the [Pipeline Templates README](https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates/-/blob/master/README.md) before using a control because the available labels and behavior evolve with the pipeline.

## Big Bang Integration

A package must remain independently installable and testable before it is integrated into the Big Bang umbrella chart. Follow [Flux Integration](flux.md) for the GitRepository and HelmRelease requirements, then use the package pipeline's integration coverage to validate the package with the required Big Bang dependencies.
