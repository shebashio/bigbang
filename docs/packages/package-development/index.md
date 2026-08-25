# Build a Big Bang Package

This page is the stable entry point for building and integrating Big Bang packages. The detailed workflow is maintained in the [Package Integration documentation](../../community/development/package-integration/index.md) so package authors have one source of truth.

A Big Bang package is a deployable Helm chart prepared for Big Bang's security, GitOps, testing, and release requirements. Shared charts such as bb-common and Gluon support that work but are not independently deployable Big Bang applications or integrated catalog entries.

## Choose a Workflow

- Use [Package Lifecycle: Onboarding](../../community/development/package-lifecycle/onboarding.md) when proposing or onboarding a supported package.
- Follow [Package Integration](../../community/development/package-integration/index.md) when adapting a Helm chart to Big Bang standards.
- Use [Extra Package Deployment](../../installation/environments/extra-package-deployment.md) when Big Bang should deploy a chart that is not an integrated package.

## Shared Package-Authoring Libraries

- [Big Bang Common Library](../../community/development/package-integration/bb-common.md) explains how package charts consume bb-common for standardized security, networking, routing, and Istio resources.
- [Testing with Gluon](../../community/development/package-integration/testing.md) explains how package charts add Gluon test jobs, Cypress tests, and script tests.
- [Pipeline Integration](../../community/development/package-integration/pipeline.md) covers package build, validation, and release workflows.

Big Bang documentation describes how these charts fit into package development. Use the [bb-common integration guide](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/INTEGRATION_GUIDE.md), [Gluon test documentation](https://repo1.dso.mil/big-bang/product/packages/gluon/-/blob/master/docs/bb-tests.md), and [Gluon README documentation](https://repo1.dso.mil/big-bang/product/packages/gluon/-/blob/master/docs/bb-package-readme.md) for their detailed values, templates, and APIs.

## Architecture and Review

Use the [Reference Package](../ref-package.md) to review application architecture, availability, identity, licensing, storage, observability, and dependencies before integration.
