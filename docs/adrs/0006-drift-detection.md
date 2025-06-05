# 6. Enabling Flux Drift Detection  

Date: 2025-06-04 

## Status 

Accepted 

## Context 

In GitOps, drift detection identifies discrepancies between the actual state of infrastructure or applications and the desired state as defined in a Git repository. Essentially, it checks if the live environment matches the configuration defined in Git which serves as the source of truth. If a mismatch or drift is detected, Flux will modify the live environment to match what is defined in Git.  This helps maintain consistency and avoid unexpected issues caused by unauthorized or undocumented changes.  To explore how drift detection works behind the scenes refer to [official documentation here](https://fluxcd.io/flux/components/helm/helmreleases/#drift-detection).

## Decision 

We will enable Flux Drift Detection in big bang packages.  It is specified in helmrelease.yaml under bigbang/chart/templates/packages_name. 

An example for enabled mode (other valid modes are warn and disabled):
```
flux:
  driftDetection:
    mode: enabled
```

1. The Big Bang 3.0 release will come preset with driftDetection enabled for all tested packages. 

2. Some newer packages such as Istio Operatorless will not have driftDetection enabled in time for 3.0 release and will be enabled soon after. 

3. Few packages in the process of phasing out will not be included.

## Consequences 

### Positive 

1. Enabling drift detection is a crucial aspect of Defense in Depth (DiD) in cybersecurity. 

2. Drift detection will constantly check for configurations such as cpu, memory, replicas or image for discrepencies with the Git repository and reconcile them.

### Negative  

1. It may take longer to deploy or upgrade.  Cpu usage for Flux may have 20-50% average increase (~200ms).  Memory may have 10-25% increase (~50 MiB). API Requests may also have noticeable increase.   

## Reference

1. [Fluxcd drift detection technical document](https://fluxcd.io/flux/components/helm/helmreleases/#drift-detection)

2. [Fluxcd cluster-state drift detection blog](https://github.com/fluxcd/helm-controller/issues/643)