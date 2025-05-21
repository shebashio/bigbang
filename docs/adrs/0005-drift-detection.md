# 5. Enabling Flux Drift Detection  

Date: 2025-05-23 

## Status 

Accepted 

## Context 

In GitOps, drift detection identifies discrepancies between the actual state of infrastructure or applications and the desired state as defined in a Git repository. Essentially, it checks if the live environment matches the configuration defined in Git which serves as the source of truth. This helps maintain consistency and avoid unexpected issues caused by unauthorized or undocumented changes. 

## Decision 

We will enable Flux Drift Detection in big bang packages.  It is specified in helmrelease.yaml under bigbang/chart/templates/packages_name. 

The Big Bang 3.0 release will come preset with driftDetection enabled for all tested packages. 

Some newer packages such as Backstage or Istio Operatorless will not have driftDetection enabled in time for 3.0 and will be enabled soon after. 

Few packages that have similar functionalities such as Alloy and Fluentbit will have Alloy enabled with drift detection and not yet for Fluentbit. 

 

## Consequences 

### Positive 

Enabling drift detection is a crucial aspect of Defense in Depth (DiD) in cybersecurity. 

Functional tests on resources such as cpu/memory, replicas and image locations will be checked and compared to what's defined in the repository.  If a discrepancy is found the values will be modified to conform with the values in the repository. 

### Negative 

Any other resources besides cpu/memory, replicas and image location needs to be checked to make sure it's in flux drift detection checklist. 

May cause more complication when upgrade to from non drift detection mode to drift detection mode. 
