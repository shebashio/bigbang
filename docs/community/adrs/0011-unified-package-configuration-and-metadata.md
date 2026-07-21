# 11. Unified Package Configuration and Package Metadata

Date: 2026-07-17

## Status

Accepted

## Context

[ADR 3](./0003-single-package-mapping.md) established the goal of placing every deployable package under one `packages` mapping. Big Bang 3.x currently exposes built-in packages in two locations: packages historically categorized as core are top-level keys such as `monitoring`, while packages historically categorized as add-ons are under keys such as `addons.gitlab`. User-supplied packages already use the `packages.<name>` mapping.

The split makes `values.yaml` difficult to scan and makes automation harder because tooling must know whether a package is core, an add-on, or user supplied before it can locate the package. A package can also change category even though its configuration contract has not changed. Category is descriptive metadata and should not determine the values hierarchy.

Moving the existing paths immediately would make otherwise valid 3.x deployment values fail. Big Bang 4.x is the appropriate release for removing those paths, but users need a migration period and an automated way to update their values before that breaking release.

The chart also repeats package identity in several places: Helm templates, schema properties, documentation navigation, compatibility lists, and migration tooling. A repository-owned package metadata catalog can become the source for those generated views without exposing implementation metadata as user-configurable Helm values.

This ADR refines ADR 3. It retains the single package mapping decision but supersedes ADR 3's proposed `additionalPackages` mapping. Built-in and user-supplied packages will coexist under `packages` because both are packages and their names must already be unique within one Big Bang release.

## Decision

The canonical package configuration path is `packages.<name>` for built-in and user-supplied packages.

The migration will be delivered in phases:

1. During Big Bang 3.x, the chart accepts both the canonical and legacy built-in paths. A render-time compatibility layer recursively merges `packages.<name>` over the corresponding top-level or `addons.<name>` defaults. The canonical path wins when both paths set the same field. Built-in entries are excluded from the generic user-supplied package renderer so they cannot be deployed twice.
2. Documentation and examples use only `packages.<name>`. Chart notes identify canonical aliases that were used, and a migration script is provided so users can update stored values before 4.x.
3. In Big Bang 4.x, built-in defaults move to `packages.<name>`, templates read those paths directly, and the legacy top-level and `addons` package paths, schemas, and compatibility normalizer are removed. Unknown entries under `packages` continue to use the generic package deployment contract.

Global configuration such as `domain`, registry credentials, network policy settings, and shared Istio configuration remains at the top level. A package's raw child-chart overrides remain nested under `packages.<name>.values`; this decision does not flatten child-chart values into the Big Bang configuration surface.

### Package metadata catalog

Before removing the compatibility layer, add a repository-owned catalog at `chart/package-metadata.yaml`. The catalog is build-time project metadata, not part of `values.yaml` and not configuration passed to a Helm release. Its initial shape is expected to be:

```yaml
apiVersion: bigbang.dev/v1alpha1
packages:
  monitoring:
    displayName: Monitoring
    category: core
    legacyPath: monitoring
    templateDirectory: monitoring
    documentation: docs/packages/core/monitoring.md
  gitlab:
    displayName: GitLab
    category: addon
    legacyPath: addons.gitlab
    templateDirectory: gitlab
    documentation: docs/packages/addons/gitlab.md
```

The package map key is the stable configuration identity. `category` is informational and may change without moving user values. `legacyPath` exists only for the 3.x-to-4.x transition and will be removed after the compatibility window. `templateDirectory` connects the public identity to the current chart implementation. `documentation` and `displayName` support generated navigation and user-facing output.

The initial catalog will deliberately not duplicate package versions, Git sources, namespaces, enablement defaults, Flux dependencies, or child-chart values. Those remain in `values.yaml` or package templates until a separate decision establishes one authoritative source for them.

A generator will validate uniqueness and required fields, then produce or check in sync the following derived artifacts:

- the Helm template map used to identify built-in packages and their legacy paths;
- built-in `packages` properties in `values.schema.json`;
- the package mappings embedded in the standalone migration script;
- package documentation navigation or indexes where practical.

CI will fail when generated artifacts differ from the catalog. Generated files will be checked into the repository so Helm rendering and the user-facing migration script do not require a runtime parser or an additional chart dependency. The catalog format is `v1alpha1` so fields can be revised as implementation experience develops.

## Migration behavior

The migration utility moves known built-in mappings as follows:

```yaml
# Big Bang 3.x
monitoring:
  enabled: true
addons:
  gitlab:
    enabled: true

# Big Bang 4.x
packages:
  monitoring:
    enabled: true
  gitlab:
    enabled: true
```

If both locations exist, the result uses the same precedence as the 3.x compatibility layer:

```yaml
monitoring:
  enabled: true
  flux:
    interval: 5m
packages:
  monitoring:
    enabled: false

# Result
packages:
  monitoring:
    enabled: false
    flux:
      interval: 5m
```

The script leaves global values, unknown `addons` entries, and existing user-supplied `packages` entries in place. Its default mode writes to standard output without changing the input. In-place operation creates a backup, and repeated execution has no additional effect.

## Consequences

Users gain one predictable location for every deployable package and can migrate incrementally during 3.x. Existing deployments remain valid throughout the compatibility window, and precedence is deterministic when both paths are present.

Maintainers temporarily carry a normalization layer and duplicate package lists. Rendering must normalize aliases before templates inspect package values. The metadata catalog and generated artifacts will remove that duplication before or as part of the 4.x migration.

The combined `packages` mapping reserves built-in package names. A user-supplied package cannot use the same key as a built-in package in that Big Bang version. This is preferable to ambiguous or duplicate Helm releases and must be enforced by schema and tests.

Removing legacy paths in 4.x remains a breaking change. Release documentation must direct users to the migration guide and require them to review the generated result, especially when both old and canonical paths were present.
