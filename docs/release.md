## Release Schedule

- Big Bang releases adopt a standardized versioning based on and loosely following the [Semantic Versioning 2.0.0 guidelines](https://semver.org/spec/v2.0.0.html) (major.minor.patch). These releases are not based on a fixed schedule and instead, follow the specifics in the scheme that is described in this section.

### Patch Version

A patch version increment is performed when there is a change in the tag (i.e., version number) of a Big Bang core package or a bug fix for a Big Bang template or values files. A change in the patch version number should be backwards compatible with previous patch changes within a minor version. If there is a significant functionality change in the a core package that requires adjustments to Big Bang templates, this would require a change in the minor or major version depending on the impact to the values and secrets used to integrated the package with Big Bang.

NOTE: Patch versions would not typically be created for addon package updates, rather customers would be expected to be updating those packages via `git.tag`/`helmRepo.tag` changes directly, or "inheriting" those updates through another version.

### Minor Version

A minor version increment is required when there is a change in the integration of Big Bang with core or addon packages. For example, the following changes warrant a Minor version change:

- Change in the umbrella values.yaml (except for changes to package version keys)
- Change in any Big Bang templates (non bug fix changes)

Minor version changes should be backwards compatible.

### Major Version

A major version increment indicates a release that has significant changes, which could potentially break compatibility with previous versions. A major change is required when there are changes to the architecture of Big Bang or critical values file keys. For example removing a core package or changing significant values that propagate to all core and add-on packages are considered major version changes. Examples of major version changes are provided in the folowing:

- Removal or renaming of Big Bang values.yaml top level keys (e.g., istio and/or git repository values).
- Change to the structure of chart/templates files or key values.
- Additional integration between core/add-on packages that require change to the charts of all packages.
- Modification of Big Bang GitOps engine (i.e., switching from FluxCD -> ArgoCD).

To see what is on the roadmap or included in a given release you can still review our [project milestones](https://repo1.dso.mil/groups/big-bang/-/milestones).
