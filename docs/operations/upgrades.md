# Upgrades

## Before Upgrading
Before upgrading Big Bang, please first check the Release Notes and the Changelog to look for any notes that apply to Big Bang Updates and Package Updates.

For Big Bang 4.0, follow [Migrating package values](../migration/migrating-package-values-for-bb4.0.md) before changing the deployment version. Built-in packages now use `packages.<name>`; the old top-level and `addons.<name>` paths fail schema validation. The migration also handles the `bb-common` values layout. For a plaintext values file:

```shell
scripts/migrate-values-3-to-4.sh --target 4 --output values-4.x.yaml values.yaml
```

Review the output and preserve values-source precedence. The migration guide covers embedded HelmRelease values, multiple sources, and SOPS-encrypted inputs. Do not deploy target-4 output to Big Bang 3.x.

There are two important things to review when upgrading:
1. "Upgrade Notices" in the Big Bang release notes: 
  - These capture any critical notes that the Big Bang development team identified during the release process. 
    - This may be an update to Flux which requires a "manual" application, or a change to a specific package that we deem important to include.
2. Changelog entries for individual packages that you are deploying: 
  - Oftentimes individual packages could have breaking changes depending on your configuration. 
  - It is important to review the changes included with those packages and determine if your configuration needs to be adjusted as a result.

## Supported Upgrades
Generally, we expect upgrades to be done one minor release at a time.  If necessary, it is possible to jump past several versions provided there is careful review of the release notes in between the versions and there are no problems.

NOTE: It is recommended that upgrades first be tested in a staging environment that mirrors the production environment so that errors are caught early.

## Upgrading a Single Package
Packages in Big Bang can be updated one at a time.
Upgrading a single package in Big Bang is done by changing the tag in the values for that package.  This should be done in the overriding values in the customer template.

For a Git repository, use these **umbrella values**, replacing the tag with the desired package version:

```yaml
packages:
  istiod:
    sourceType: "git"
    git:
      repo: https://repo1.dso.mil/big-bang/product/packages/istiod.git
      path: "./chart"
      tag: "PACKAGE_VERSION"
```

For a Helm repository, use these **umbrella values**:

```yaml
packages:
  istiod:
    sourceType: "helmRepo"
    helmRepo:
      repoName: "registry1"
      chartName: "istiod"
      tag: "PACKAGE_VERSION"
```

These values are in `chart/values.yaml` of the Big Bang helm chart.
Review the package's upgrade notes for required umbrella and dependency changes; changing a tag alone does not establish compatibility. Istio components, for example, may require coordinated version changes.

When using the [Customer Template](https://repo1.dso.mil/big-bang/customers/template), choose the directory for your deployment strategy:

| Strategy | Shared values | Environment values |
| --- | --- | --- |
| `gitRepo` | `gitRepo/base/configmap.yaml` | `gitRepo/dev/configmap.yaml` |
| `helmRepo` | `helmRepo/base/configmap.yaml` | `helmRepo/dev/configmap.yaml` |

In `gitRepo`, these are raw values files consumed by Kustomize's ConfigMap generator. In `helmRepo`, edit the values embedded under `data.values.yaml` in the ConfigMap, preserving its metadata and other values. Adapt paths if you copied a strategy directory into your own repository root.

## Upgrading Big Bang umbrella deployment
Replace `BIG_BANG_VERSION` below with the target release. Keep other resources and patches already present in your files.

### Git repository strategy

To update every environment using the shared base, edit the remote resource `ref` in [`gitRepo/base/kustomization.yaml`](https://repo1.dso.mil/big-bang/customers/template/-/blob/main/gitRepo/base/kustomization.yaml). This **Kustomization fragment** shows the versioned resource; retain the existing `flux-components.yaml` resource and ConfigMap/Secret configuration:
```yaml
resources:
  - https://repo1.dso.mil/big-bang/bigbang.git//base?ref=BIG_BANG_VERSION
  - flux-components.yaml
```

To test a version in one environment, edit the existing `GitRepository/bigbang` patch in [`gitRepo/dev/kustomization.yaml`](https://repo1.dso.mil/big-bang/customers/template/-/blob/main/gitRepo/dev/kustomization.yaml). The following is a **resource patch fragment**, not a standalone Kustomization:
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: bigbang
spec:
  ref:
    $patch: replace
    tag: "BIG_BANG_VERSION"
```

### Helm repository strategy

To update all environments using the shared base, edit `spec.chart.spec.version` in [`helmRepo/base/helmrelease.yaml`](https://repo1.dso.mil/big-bang/customers/template/-/blob/main/helmRepo/base/helmrelease.yaml). The base's Kustomize replacement copies that version into `GitRepository/bigbang.spec.ref.tag` for Flux controller manifests.

To override one environment, append both patches below to its existing `patches` list, for example in `helmRepo/dev/kustomization.yaml`. This **Kustomization fragment** keeps the chart and controller source versions aligned; preserve the existing values-source patches:

```yaml
patches:
  - target:
      kind: HelmRelease
      name: bigbang
    patch: |-
      - op: replace
        path: /spec/chart/spec/version
        value: "BIG_BANG_VERSION"
  - target:
      kind: GitRepository
      name: bigbang
    patch: |-
      - op: replace
        path: /spec/ref/tag
        value: "BIG_BANG_VERSION"
```

### Flux controller alignment in Customer Template

The customer template includes a `flux-components` Kustomization in base for both `gitRepo` and `helmRepo` strategies so Flux can reconcile Flux controller manifests from Big Bang `base/flux`.

- For `gitRepo`, update the base `ref` and Flux components follow that same source revision.
- For `helmRepo`, update `helmRepo/base/helmrelease.yaml` `spec.chart.spec.version`; the template syncs the `GitRepository/bigbang` tag from that version.

If you override the Big Bang version in an environment overlay, also override the `GitRepository/bigbang.spec.ref.tag` in that overlay to keep Flux controllers and Big Bang on matching revisions.

## Verifying the Upgrade
After upgrading the cluster, there are some places to look to verify that the upgrade was completed successfully.

### Verify Helm releases

Successful HelmReleases should report `READY=True`. Check that the applied revision is the intended version; a Ready resource may still represent the previous release if its source has not updated. Also check sources and Kustomizations:

```shell
flux get helmreleases -A
flux get sources all -A
flux get kustomizations -A
```

### Verify Pods

Verify that long-running Pods are Ready and that Jobs have completed successfully. Investigate failed Pods and repeated restarts:

```shell
kubectl get pods -A
```

Example output:

```text
NAMESPACE           NAME                                                        READY   STATUS    RESTARTS   AGE
kube-system         local-path-provisioner-5ff76fc89d-xd85h                     1/1     Running   0          22m
...
monitoring          alertmanager-monitoring-monitoring-kube-alertmanager-0      3/3     Running   7          3m
```

### Verify Image Versions for Specific Packages

For sidecar-mode workloads, check the workload's `istio-proxy` image as well as the Istio control plane, including mission applications. The first image in `istio-system` does not establish the sidecar versions running elsewhere. For ambient deployments, also verify Istio CNI, ztunnel, and any waypoints against the target release.

List container names and images for a selected Pod; compare with the target package's image metadata, since chart and application versions can differ:

```shell
kubectl get pod POD_NAME -n NAMESPACE \
  -o jsonpath='{range .spec.containers[*]}{.name}{"\t"}{.image}{"\n"}{end}'
```

### Check Package Usability
 - Validate the UI for web applications loads properly.
   - This could be through a basic `curl` check or similar to confirm UIs are up and healthy.
 - You may configure and use certain applications in unique ways.
   - It is important to validate those specific applications/features are functioning as expected post-upgrade.

## Upgrade Troubleshooting

If an upgrade fails, see [Troubleshoot a Big Bang deployment](troubleshooting/index.md#upgrade-problems) to identify the first resource that is not ready and troubleshoot the failure.
