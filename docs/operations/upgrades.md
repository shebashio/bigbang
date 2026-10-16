# Upgrades

## Before Upgrading

Before upgrading Big Bang, check the release notes and changelogs for changes that may affect your deployment.

There are two important things to review when upgrading:
1. "Upgrade Notices" in the Big Bang release notes: 
  - These capture any critical notes that the Big Bang development team identified during the release process. 
    - This may be an update to Flux which requires a "manual" application, or a change to a specific package that we deem important to include.
2. Changelog entries for individual packages that you are deploying: 
  - Oftentimes individual packages could have breaking changes depending on your configuration. 
  - It is important to review the changes included with those packages and determine if your configuration needs to be adjusted as a result.

## Supported Upgrades
Generally, we expect upgrades to be done one minor release at a time.  If necessary, it is possible to jump past several versions provided there is careful review of the release notes in between the versions and there are no problems.

Test upgrades in a staging environment that mirrors production to identify issues before upgrading production.

## Upgrading a Single Package

Packages in Big Bang can be updated one at a time by changing the version tag in the package's values override.

For a Git repository:

```yaml
istiod:
  sourceType: "git"
  git:
    repo: https://repo1.dso.mil/big-bang/product/packages/istiod.git
    path: "./chart"
    tag: "<package-version>"
```

For a Helm repository:

```yaml
istiod:
  sourceType: "helmRepo"
  helmRepo:
    repoName: "registry1"
    chartName: "istiod"
    tag: "<package-version>"
```

These values are defined in `chart/values.yaml` of the Big Bang Helm chart.

When using the [Customer Template](https://repo1.dso.mil/big-bang/customers/template), make these changes in either:

- The base values (`bigbang/base/values.yaml`) to update shared configuration.
- An environment-specific values file (for example, `bigbang/dev/configmap.yaml`) to update one environment.

Review the package changelog and confirm compatibility with your Big Bang version before upgrading an individual package.

## Upgrading Big Bang Umbrella Deployment

When using the [Customer Template](https://repo1.dso.mil/big-bang/customers/template), you have two options for upgrading the Big Bang umbrella deployment.

### Update All Environments

Edit `base/kustomization.yaml` and change the base `ref` to the new version. This updates all environments that use the base configuration.

```yaml
namespace: bigbang
resources:
  - https://repo1.dso.mil/big-bang/bigbang.git//base?ref=<target-version>
```

### Update a Single Environment

Edit the environment-specific Kustomization (for example, `dev/kustomization.yaml`) and update the version in its `ref` patch.

```yaml
spec:
  interval: 1m
  ref:
    $patch: replace
    tag: "<target-version>"
```

This example shows only the relevant portion of the existing `GitRepository` patch.

### Flux Controller Alignment in Customer Template

The Customer Template includes a `flux-components` Kustomization for both `gitRepo` and `helmRepo` strategies. This allows Flux to reconcile its controller manifests from Big Bang's `base/flux` directory.

- **`gitRepo`:** Update the base `ref`. Flux components follow the same source revision.
- **`helmRepo`:** Update `spec.chart.spec.version` in `base/helmrelease.yaml`. The template synchronizes the `GitRepository/bigbang` tag with that version.

If you override the Big Bang version for a specific environment, also update `GitRepository/bigbang.spec.ref.tag` in that environment to keep Flux controllers and Big Bang on matching versions.

## Verifying the Upgrade

After upgrading Big Bang, verify that the Helm releases, Pods, and applications are working as expected.

### Verify Helm Releases

Check that all Helm releases have reconciled successfully:

```shell
flux get helmreleases -A
```

Successful releases should show `READY=True` and a status such as `Release reconciliation succeeded`.

Also check that Flux sources and Kustomizations are ready:

```shell
flux get sources all -A
flux get kustomizations -A
```

### Verify Pods

Check that Pods are running or have completed successfully. Look for failed Pods or Pods that have restarted repeatedly.

```shell
kubectl get pods -A
```

For Pods with issues, inspect their status and events:

```shell
kubectl describe pod <pod-name> -n <namespace>
```

### Verify Image Versions for Specific Packages

Check the running image version to confirm that a package updated as expected:

```shell
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.containers[*].image}'
```

Image versions may differ from Helm chart versions, so compare them with the expected versions for your upgrade.

For workloads using Istio sidecars, verify that the sidecar versions are compatible with the upgraded Istio control plane, including workloads outside Big Bang core and addons.

### Check Package Usability

- Verify that web application interfaces load correctly. A basic `curl` check can help confirm that an endpoint is responding.
- Test application features and integrations that your environment uses, especially those affected by the upgrade.

## Upgrade Troubleshooting

If an upgrade fails, identify the affected package and review its release notes and changelog for changes that may have been missed.

See [Troubleshoot a Big Bang deployment](troubleshooting/index.md) for steps to diagnose Flux and HelmRelease failures.