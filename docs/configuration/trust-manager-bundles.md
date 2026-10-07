# Trust-manager bundles

Big Bang has two separate maintained packages for trust-manager:

- [`cert-manager-trust-manager`](https://repo1.dso.mil/big-bang/product/maintained/cert-manager-trust-manager) provides the trust-manager controller, webhook, `Bundle` CRD, and upstream default-package behavior.
- [`cert-manager-trust-manager-bundle`](https://repo1.dso.mil/big-bang/product/maintained/cert-manager-trust-manager-bundle) provides the optional aggregate `Bundle`, DoD source artifact, source selection, and target configuration.

The aggregate Bundle is **disabled by default**. Enable it only when workloads need the package-managed trust bundle.

## Package ordering

Install and reconcile `cert-manager-trust-manager` before `cert-manager-trust-manager-bundle`. The bundle package creates a normal Helm-managed `Bundle` custom resource and depends on the controller package's CRD and webhook.

The two packages have independent Helm lifecycles. Enabling the bundle package does not enable the controller package, and the bundle package does not inspect or mutate the separate trust-manager release.

## DoD trust bundle

Enable the controller package and the bundle package explicitly. These package repositories are maintained separately from the umbrella chart, so the example includes the `packageConfiguration.version: v1` discriminator and Git source fields required for custom package entries. Pin each package to an approved release tag for the environment:

```yaml
packageConfiguration:
  version: v1

packages:
  cert-manager-trust-manager:
    enabled: true
    sourceType: git
    git:
      repo: https://repo1.dso.mil/big-bang/product/maintained/cert-manager-trust-manager.git
      path: chart
      tag: v0.22.1-bb.8

  cert-manager-trust-manager-bundle:
    enabled: true
    sourceType: git
    git:
      repo: https://repo1.dso.mil/big-bang/product/maintained/cert-manager-trust-manager-bundle.git
      path: chart
      tag: 0.1.0-bb.3
    values:
      bundle:
        enabled: true
        sources:
          dod:
            enabled: true
```

The DoD source is the package-owned, provenance-tracked Cyber Exchange artifact. It is not a certificate-generation or private-key-management feature.

## Public trust bundle

Public trust is an explicit two-package contract. Use the same complete package source configuration as above, then enable the upstream default package in `cert-manager-trust-manager` and the public source in `cert-manager-trust-manager-bundle`:

```yaml
packageConfiguration:
  version: v1

packages:
  cert-manager-trust-manager:
    enabled: true
    sourceType: git
    git:
      repo: https://repo1.dso.mil/big-bang/product/maintained/cert-manager-trust-manager.git
      path: chart
      tag: v0.22.1-bb.8
    values:
      upstream:
        defaultPackage:
          enabled: true

  cert-manager-trust-manager-bundle:
    enabled: true
    sourceType: git
    git:
      repo: https://repo1.dso.mil/big-bang/product/maintained/cert-manager-trust-manager-bundle.git
      path: chart
      tag: 0.1.0-bb.3
    values:
      bundle:
        enabled: true
        sources:
          public:
            enabled: true
```

Do not enable the bundle package's public source without also enabling the controller package's upstream default package. Public trust remains opt-in and is not enabled by default.

## Source and target behavior

The aggregate Bundle can combine the supported DoD, public, and custom sources. Initial target support is ConfigMap. Workloads must mount or reference the generated target themselves; creating a Bundle does not automatically change workload configuration.

The default target is namespace-scoped. An omitted or explicitly empty namespace selector targets the configured trust-manager namespace. Configure an explicit label or expression selector when the trust material should be distributed to another namespace set. This package does not currently provide an all-namespaces opt-in.

Secret targets and workload mount/reference configuration are follow-up scope. After the companion package documentation is published on its default branch, use the [`CMTMB package overview`](https://repo1.dso.mil/big-bang/product/maintained/cert-manager-trust-manager-bundle/-/blob/main/docs/overview.md) and [`CMTMB maintenance guide`](https://repo1.dso.mil/big-bang/product/maintained/cert-manager-trust-manager-bundle/-/blob/main/docs/DEVELOPMENT_MAINTENANCE.md) for the complete source, selector, target, schema, lifecycle, collision, provenance, and maintenance contract.

After the companion package documentation is published on its default branch, use the [`CMTM package overview`](https://repo1.dso.mil/big-bang/product/maintained/cert-manager-trust-manager/-/blob/main/docs/overview.md) and [`CMTM maintenance guide`](https://repo1.dso.mil/big-bang/product/maintained/cert-manager-trust-manager/-/blob/main/docs/DEVELOPMENT_MAINTENANCE.md) for controller, webhook, CRD, and upstream default-package behavior.

## Lifecycle and collisions

The aggregate Bundle is a normal Helm resource, not a Helm hook. Normal install, upgrade, rollback, disablement, rename, and uninstall behavior therefore applies.

Because a `Bundle` is cluster-scoped, the package fails closed when the configured name already exists without matching Helm ownership metadata. Review and adopt an existing resource explicitly before enabling the package; it will not silently take ownership.
