# 3. Passthrough Package Helm Charts

Date: 2025-04-04

## Status

<unknown>

## Context

The passthrough helm chart pattern was developed as a way for the internal Big Bang engineering team to both speed up renovates as well as curb the reliance on an outdated and no longer support version of the [kpt](https://kpt.dev/) tool. This patten simply involves utilizing the upstream creator's chart as a helm dependency and layering the default values required to run the chart within the compliance standards of Big Bang.

## Decision

## Consequences 
