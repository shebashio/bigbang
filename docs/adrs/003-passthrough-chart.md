# 3. Passthrough Package Helm Charts

Date: 2025-04-04

## Status

<unknown>

## Context

The passthrough helm chart pattern was developed as a way for the internal Big Bang engineering team to both speed up renovates as well as curb the reliance on an outdated and no longer support version of the [kpt](https://kpt.dev/) tool. This patten simply involves utilizing the upstream creator's chart as a helm dependency and layering the default values required to run the chart within the compliance standards of Big Bang.

## Decision

Creating a passthrough chart pattern is relatively simple. Using the command `helm dependency add <upstream dependent chart>` will add the upstream chart to the helm dependencies for the internal big back package, pulling it as a tarfile. Sample renovate config is listed below for automating the new helm dependency update. 

In order to convert an existing `kpt` configured chart, the process is slightly more complicated. Remove all forked upstream template files, not Big Bang created template files, while making note of any changes made to the upstream template files. Run the `helm dependency add <upstream dependent chart>` to add the chart as a dependency. Changes made to the template files can the be attempted to be made within the `values.yaml` file. For any changes that cannot be applied via `values.yaml`, a post renderer will need to be created in the Big Bang Repository. 

Sample Renovate package rule from:

```yaml
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

Sample post renderer config: 

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

## Consequences 
