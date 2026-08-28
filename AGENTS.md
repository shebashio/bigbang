# AGENTS.md
<!-- big-bang-agents-standard: 1 -->

## Repository Purpose

This repository owns the Big Bang umbrella Helm chart, its bootstrap manifests,
integrated-package orchestration, configuration schema, migration utilities, and
central documentation. The chart renders Flux sources and reconciliation
resources; it does not contain the independently versioned package charts it
deploys.

Make umbrella-wide configuration, package wiring, dependency, generation, and
documentation changes here. Make workload templates, package defaults, and
package-specific tests in the corresponding package repository. General product
behavior remains owned by the upstream project.

## Sources of Truth

- `chart/package-metadata.yaml` defines built-in package identity, category,
  legacy path, implementation directory, and integration documentation.
- `chart/values.yaml` defines source pins, defaults, and user-facing value
  documentation.
- `chart/values.schema.json` defines the public values contract and valid types.
- `chart/templates/` defines rendered behavior. `_helpers.tpl` contains shared
  source, values, alias, dependency, ambient, and network-policy contracts.
- `base/` defines the Kustomize and Flux bootstrap path for the umbrella chart.
- `chart/unittests/` contains Helm unit tests; `tests/bats/` contains shell,
  generator, migration, and overlay tests.
- `CONTRIBUTING.md`, `docs/README.md`, and
  `docs/community/development/` define current contribution and documentation
  practices.
- CI is configured through the GitLab project setting
  `pipelines/bigbang.yaml@big-bang/pipeline-templates/pipeline-templates:master`;
  there is no repository-local `.gitlab-ci.yml`.

When prose conflicts with the selected release's chart, schema, templates, or
tests, verify the intended policy and correct the stale documentation in the
same change.

## Repository Layout

- `chart/`: umbrella chart, values contract, generated package metadata, Helm
  templates, and unit tests.
- `base/`: GitOps bootstrap resources and pinned Flux installation manifests.
- `docs/`: published user, operator, package-integration, and contributor docs.
- `scripts/`: generators, migration tools, rendering tools, and cluster
  operations.
- `tests/`: shared deployment values and Bats suites.
- `blog/`: release and feature articles, including historical material.

## Working Rules

- Treat each `chart/templates/<package>/` family atomically. Inspect its source,
  credentials, values, namespace, image-pull Secret, HelmRelease, migrations,
  post-renderers, special Secrets, and tests before changing gates or names.
- Preserve `bigbang.normalizePackageAliases` at rendering entry points. Test
  both legacy configuration and `packageConfiguration.version: v1` when changing
  package normalization or schema behavior.
- Under v1, canonical built-in values override legacy values. Without v1,
  `packages.<name>` retains the legacy custom-package meaning. Unknown names
  remain custom packages in both modes.
- Preserve values precedence: `common`, then generated `defaults`, then user
  `overlays`. Sprig merge operations mutate their first argument, so deep-copy
  values before using `set`, `unset`, `merge`, or `mergeOverwrite`.
- Treat Flux names, namespaces, source references, values Secret names,
  HelmRelease names, and `dependsOn` entries as an API. Do not infer them only
  from directory names.
- `offline: true` suppresses package GitRepository creation only. It does not
  mirror artifacts, rewrite URLs, block network access, or remove source
  references from HelmReleases.
- Ambient mode is effective when global ambient mode or ztunnel enables it.
  Preserve Istio CNI, ztunnel, Gateway API, policy, HBONE, and dependency
  behavior together.
- `_bb-common-migrations.tpl` and deprecated aliases are compatibility code.
  Remove them only at the documented major-version boundary with focused
  legacy and canonical tests.
- Prefer package values, `bb-common`, or a focused post-renderer over copying
  package workload templates into this chart.
- Do not manually bump the umbrella chart version in a normal merge request.

## Commands

Run commands from the repository root.

Fast, read-only checks:

```shell
scripts/validate-agents.sh
scripts/generate-package-schemas.sh --check
scripts/generate-values-reference.sh --check
helm lint ./chart
```

Helm unit tests:

```shell
helm unittest chart -f 'unittests/**/*_test.yaml'
```

Shell and generator tests:

```shell
bats --jobs 4 --recursive tests/bats/
```

Bootstrap rendering checks:

```shell
kubectl kustomize ./base >/dev/null
kubectl kustomize ./base/flux >/dev/null
```

Install hooks with `lefthook install`, or run the configured checks manually:

```shell
lefthook run pre-commit
lefthook run pre-push
```

## Validation

| Change area | Required focused checks | Additional validation |
|---|---|---|
| `AGENTS.md` or its standard | `scripts/validate-agents.sh`; `bats tests/bats/validate-agents/` | Verify referenced commands and external links manually. |
| Package metadata, canonical schema, or migration mappings | `scripts/generate-package-schemas.sh --check`; focused generator and migration Bats | Review every generated diff. |
| Chart values or generated values documentation | `scripts/generate-values-reference.sh --check`; `helm lint ./chart` | Render relevant legacy and v1 overlays. |
| Shared helpers, package gates, values merge, names, or dependencies | Focused `helm unittest` suite | Run the full Helm unit suite and render enabled/disabled, Git/Helm, and online/offline cases that changed. |
| Ambient, Istio, network policy, or authorization behavior | Relevant Helm unit tests; `tests/bats/values-overlays/values-overlays.bats` | Render both ordinary and ambient test values; use an umbrella integration environment for cross-package behavior. |
| Shell scripts | Focused Bats suite | `bats --jobs 4 --recursive tests/bats/` and ShellCheck in CI. |
| Bootstrap resources or Flux manifests | `kubectl kustomize ./base`; `kubectl kustomize ./base/flux` | Test the exact release/bootstrap path in a disposable environment. |

Package integration, clean-install, upgrade, and infrastructure tests run in
external CI and may require protected credentials. Do not substitute a local
chart-only render for required cross-package evidence.

## Big Bang Integration

The bootstrap Kustomization installs this chart as a Flux HelmRelease. The chart
then creates separately pinned sources and releases for enabled packages. A
package change can therefore require coordinated work in three places:

- The package repository owns its chart implementation, package values, tests,
  upgrade notes, and Big Bang-specific package additions.
- This repository owns package enablement, source pins, dependency ordering,
  global-to-package value mapping, and umbrella integration.
- The upstream project owns the complete product and upstream chart
  configuration surface.

For upstream passthrough configuration, document only the parent entry point and
link to version-appropriate upstream values. Do not copy nested upstream keys
into umbrella or package documentation.

## Safety and Credentials

- Never add real credentials, certificates, private keys, license data, or
  production endpoints to defaults, fixtures, rendered output, logs, or commits.
- `scripts/template-all.sh` is networked. It clones or fetches package sources,
  hard-resets its local source cache, adds Helm repositories, and may log in to
  registries. Review its cache and credential context before running:

  ```shell
  ./scripts/template-all.sh ./chart
  ```

- `scripts/install_flux.sh`, `scripts/sync.sh`,
  `scripts/remove-ns-finalizer.sh`, and restart modes in
  `scripts/istio-sidecars.sh` mutate a cluster. Run them only with explicit
  authorization and after confirming the active kubeconfig and cluster.
- GitLab triage scripts can create or modify issues. Use their documented dry-run
  modes first and verify the target project or group.
- Do not weaken policy, mesh, TLS, or network controls merely to make a render or
  deployment pass. Diagnose the owning integration and test the intended fix.

## Generated Files

- Edit `chart/package-metadata.yaml`, then run
  `scripts/generate-package-schemas.sh --write` to update canonical schema
  blocks, migration metadata, package indexes, and generated navigation. Run
  the same command with `--check` afterward.
- Edit `chart/Chart.yaml`, `chart/values.yaml`, or
  `docs/configuration/base-config.md.gotmpl`, then run
  `scripts/generate-values-reference.sh --write`. Do not edit
  `docs/configuration/base-config.md` directly.
- `base/flux/gotk-components.yaml` is generated by Flux. Follow the regeneration
  instructions maintained in `renovate.json`; do not hand-edit it.
- Review generated output before committing. A successful generator is not proof
  that the semantic change is correct.

## Authoritative References

- [Repository agent-instruction standard](docs/community/development/agent-instructions.md): required structure, linking rules, and maintenance process.
- [Contributing](CONTRIBUTING.md): contribution, security, versioning, and generated-document rules.
- [Documentation structure](docs/README.md): navigation and relative-link conventions.
- [CI workflow](docs/community/development/ci-workflow.md): external package and umbrella pipelines.
- [Passthrough chart ADR](docs/community/adrs/0005-passthrough-chart.md): upstream dependency model.
- [Upstream values documentation ADR](docs/community/adrs/0010-upstream-values-readme-documentation.md): upstream-linking boundary.
- [Unified package configuration ADR](docs/community/adrs/0011-unified-package-configuration-and-metadata.md): canonical package identity and v1 behavior.
