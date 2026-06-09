# Release Schedule

Big Bang releases use standardized versioning based on, and loosely following, the [Semantic Versioning 2.0.0 guidelines](https://semver.org/spec/v2.0.0.html): major.minor.patch. Releases are not based on a fixed schedule. The type of version increment depends on the kind of change being released.

### Patch Version

A patch version increment is performed when there is a change in the tag, or version number, of a Big Bang core package or a bug/security fix for a Big Bang template or values file. Patch changes should be backwards compatible with previous patch changes within a minor version.

If a core package change requires significant adjustments to Big Bang templates, the change may require a minor or major version increment depending on the impact to values and secrets used to integrate the package with Big Bang.

Patch versions are not typically created for add-on package updates. Customers are generally expected to update add-on packages through `git.tag` or `helmRepo.tag` changes directly, or inherit those updates through another Big Bang version.

### Minor Version

A minor version increment is required when there is a change in the integration of Big Bang with core or add-on packages. For example, the following changes warrant a minor version change:

- Change in the umbrella `values.yaml`, except for changes to package version keys
- Change in any Big Bang templates (non bug fix changes)

Minor version changes should be backwards compatible when Big Bang controls the API surface. Upstream package changes may introduce behavior that is not fully backwards compatible, even when Big Bang releases the integration as a minor version update.

### Major Version

A major version increment indicates a release with significant changes that may break compatibility with previous versions. A major change is required when there are changes to the architecture of Big Bang or critical values file keys. Removing a core package or changing significant values that propagate to all core and add-on packages are examples of major changes.

- Removal or renaming of Big Bang values.yaml top level keys (e.g., istio and/or git repository values).
- Change to the structure of chart/templates files or key values.
- Additional integration between core/add-on packages that require change to the charts of all packages.
- Modification of the Big Bang GitOps engine, such as switching from Flux to Argo CD.

To see what is on the roadmap or included in a given release, review the [project milestones](https://repo1.dso.mil/groups/big-bang/-/milestones).
