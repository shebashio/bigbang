# 8. Generate Images Metadata from Explicit Container Image References

Date: 2025-09-18

## Status

Accepted

## Context

Optimizing the Big Bang Release Pipeline

## Decision

The `smoke tests` stage and its jobs (`clean install all-packages` and `clean install oci all-packages`) have been eliminated from the Big Bang release pipeline since each package is tested individually as part of the package pipeline. 

## Consequences

### Comparing Old and New Pipelines

[Old Release Pipeline Run for `3.3.0`](https://repo1.dso.mil/big-bang/bigbang/-/pipelines/4389354) (1:09:44)

![Old Pipeline](assets/images/images-v2-metadata-files/old-pipeline.png)

And, because the `clean install all-packages` job failed regularly, this pipeline would typically need to be run 3–5
times for every release, bringing the total pipeline time (not including fixing) to approximately 4:39:56 on average.

[New Release Pipeline Run for `3.6.0`](https://repo1.dso.mil/big-bang/bigbang/-/pipelines/4495018) (0:19:11):

![New Pipeline](assets/images/images-v2-metadata-files/new-pipeline.png)

| Pipeline                  | Time            |            |
|---------------------------|-----------------|------------|
| Old (avg across 3-5 runs) | `4:39:56`       | ██████████ |
| New                       | `0:19:11`       | █          |
| **Savings**               | `4:20:45` (93%) |            |

That is a **93% savings in time** for every release!
