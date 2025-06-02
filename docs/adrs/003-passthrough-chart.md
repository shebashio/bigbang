# 3. Passthrough Package Helm Charts

Date: 2025-04-04

## Status

<unknown>

## Context

The Big Bang team is moving forward with using the passthrough helm chart pattern wherever possible. This pattern is intended to reduce the maintenance workload and complexity of the [Renovate](https://github.com/renovatebot/renovate) process for Big Bang packages. The new pattern will also reduce our dependency on an outdated and unsupported version of the [kpt](https://kpt.dev/) tool. Rather than using a third-party tool to sync changes from the upstream chart, the passthrough pattern references the upstream chart as a helm dependency and adds a configuration layer of values required to run the chart within the compliance standards of Big Bang.

## Decision

Creating a passthrough chart pattern is relatively simple. Using the command `helm dependency add <upstream dependent chart>` will add the upstream chart to the helm dependencies for the internal big back package, pulling it as a tarfile. Sample renovate config is listed below for automating the new helm dependency update.

In order to convert an existing `kpt` configured chart, the process is slightly more complicated:

1. The `kptfile` and all forked upstream template files should be removed from the repository (while making note of any changes made to the upstream template files)
2. Big Bang created template files should remain in the repository
3. Run `helm dependency add <upstream dependent chart>` to add the upstream chart as a dependency
4. Recreate any changes made to the forked template files within the `values.yaml` file (any changes that cannot be applied via overrides in `values.yaml` will require a [post-renderer](https://docs-bigbang.dso.mil/latest/docs/developer/post_renderers/) created in the Big Bang Repository) OR navigate to the upstream project and make a contribution

Sample Renovate config rule from:

```json
    {
      "customType": "regex",
      "description": "Update <chart> version>",
      "fileMatch": ["^chart/Chart\\.yaml$"],
      "matchStrings": ["version:\\s+(?<currentValue>.+)-bb\\.\\d+"],
      "depNameTemplate": "<chart-name>",
      "datasourceTemplate": "helm",
      "registryUrlTemplate": "<upstream helm repository>"
    }
```

Sample post-renderer config: 

```yaml
    {{- toYaml $fluxSettings<package> | nindent 2 }}
    {{- if or .Values.addons.<package>.postRenderers .Values.addons.<package>.postRenderersInternallyCreated}}
    postRenderers:
    {{- if .Values.addons.<package>.postRenderersInternallyCreated }}
    {{ include "<package>.postRenderersInternallyCreated" . | nindent 2 }}
    {{- end }}
    {{- with .Values.addons.<package>.postRenderers }}
    {{ toYaml . | nindent 2 }}
    {{- end }}
    {{- end }}
```

Big Bang internally created template files(e.g. `NetworkPolicy`s, `AuthorizationPolicy`s, etc.) will still be created under the `chart/templates/bigbang/` directory, with the aim being that commonly utilized template files will be consolidated into a repository within repo1.dso.mil for all packages to pull from in the future.

## Consequences 

Users will no longer be able to view the package values directly in the Big Bang package git repository. The `values.yaml` file will exist in a passthrough sub-chart tarfile bundle, which is still stored in the git repo, but not viewable from the GitLab console directly. The upstream GitHub repository for each sub-chart linked in the Big Bang chart's `README` can be used for viewing the `values.yaml` file and template files, however users should take care to ensure they are viewing the correct version of the files that is deployed via the passthrough sub-chart.

Another consequence of this passthrough chart pattern is that values settings will be abstracted one further layer than previously, requiring internal engineers and customers to modify their existing values overrides. Instead of previously where simply `.Values.<package-name>.<value-to-set>` was the way to access values on a package, now you will need to access it by also providing the upstream chart name, for example: `.Values.<package-name>.values.<upstream-chart-name>.<value-to-set>`. 

While setting values in an override file, additional nesting is also required. An example for enabling logs and pod logs in Big Bang's implementation of [Grafana Alloy](https://repo1.dso.mil/big-bang/product/packages/alloy) (which follows this passthrough pattern) is provided below:

```yaml
  # Package name
  alloy:
    enabled: true
    git:
      tag: null
      branch: alloy-92/add-dynamic-netpol
    values:
      # Upstream Chart Name
      k8s-monitoring:
        alloy-logs:
          enabled: true
        podLogs: 
          enabled: true 
```