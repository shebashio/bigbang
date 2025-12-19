# Integration: Overview

The following documents should be followed, in order, to fully integrate a new package into Big Bang:

- [ ] 1. [Get BBTOC Approval](https://repo1.dso.mil/big-bang/product/bbtoc/-/blob/master/process/Package%20Maintenance%20Tracks.md): Follow the BBTOC Package Maintenance Tracks process to get approval for package integration
- [ ] 2. [Upstream Helm Chart](upstream.md): Initialize package workspace using an upstream Helm chart
- [ ] 3. [CICD Pipeline](pipeline.md): Establish a baseline package pipeline for testing changes
- [ ] 4. [Flux Helm Chart](flux.md): Create Flux compatible GitOps Helm chart required by Big Bang
- [ ] 5. [Service mesh](service-mesh.md): Integrate with service mesh for ingress/egress
- [ ] 6. [Monitoring](monitoring.md): Enable metrics scraping on product
- [ ] 7. [Database](database.md): If required, add internal and external database support using Big Bang values
- [ ] 8. [Object Storage](storage.md): If required, add internal or external object storage support using Big Bang values
- [ ] 9. [Single-Sign On](sso.md): If available, add Single-Sign On (SSO) through internal or external identify provider
- [ ] 10. [Additional Tests](testing.md): Add testing to validate basic functionality
- [ ] 11. [Network Policies](network-policies.md): Add ingress/egress policies to restrict network traffic for security
- [ ] 12. [Policy Enforcement](policy-enforcement.md): Update package to comply with default security and governance policies in Big Bang
- [ ] 13. [Istio Hardening](istio-hardened.md): Update package to comply with Istio hardening policies in Big Bang
- [ ] 14. [Supported Package](supported.md): Migrate package into the Big Bang repo as a supported package
- [ ] 15. [Final Documentation](documentation.md): Add additional Big Bang documentation for final release
- [ ] 16. [Big Bang Merge Request](bigbang-merge-request.md): Create Big Bang Merge Request and run all packages pipeline
