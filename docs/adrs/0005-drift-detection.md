# 5. Enabling Flux Drift Detection  

Date: 2025-05-23 

## Status 

Accepted 

## Context 

In GitOps, drift detection identifies discrepancies between the actual state of infrastructure or applications and the desired state as defined in a Git repository. Essentially, it checks if the live environment matches the configuration defined in Git which serves as the source of truth. If there is a mismatch or a drift is detected, Flux will modify the live environment back to what is defined in Git.  This helps maintain consistency and avoid unexpected issues caused by unauthorized or undocumented changes. 

## Decision 

We will enable Flux Drift Detection in big bang packages.  It is specified in helmrelease.yaml under bigbang/chart/templates/packages_name. 

The Big Bang 3.0 release will come preset with driftDetection enabled for all tested packages. 

Some newer packages such as Backstage or Istio Operatorless will not have driftDetection enabled in time for 3.0 release and will be enabled soon after. 

Few packages in the process of phasing out will also not be included.

## Consequences 

### Positive 

Enabling drift detection is a crucial aspect of Defense in Depth (DiD) in cybersecurity. 

Drift detection on resources such as cpu/memory, replicas and image locations will be active for enabled packages.

### Negative  

It might take longer to deploy or upgrade. 

May need more resources such as cpu/memory/storage and network bandwidth.

## Reference

[Fluxcd drift detection technical document](https://fluxcd.io/flux/components/helm/helmreleases/#drift-detection)

[Fluxcd cluster-state drift detection blog](https://github.com/fluxcd/helm-controller/issues/643)