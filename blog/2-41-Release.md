---
revision_date: Last edited December 09, 2024
tags:
  - blog
---

# Big Bang Release 2.41.0: A Milestone in Enterprise Platform Development

We are thrilled to announce the release of Big Bang 2.41.0, marking another significant step forward in our enterprise platform development journey. This incremental release brings substantial improvements to stability, security, and core functionality across our component ecosystem.

## Release Highlights

The latest release includes comprehensive updates to critical components including GitLab, Istio, Kiali, and Kyverno. Our development teams have worked diligently to ensure these updates enhance both performance and security while maintaining seamless integration within the Big Bang ecosystem.

## Team Achievements and Progress

### Infrastructure Evolution

Our infrastructure team has made substantial progress in modernizing our platform architecture. A major initiative currently underway is the strategic transition from RKE2 to EKS. The team has created a comprehensive migration plan and established an epic to guide this crucial transformation. Additionally, they are advancing the Repo Sync project toward MVP status while conducting thorough EKS cluster deployment testing.

### Storage and Collaboration Enhancements

The storage team has delivered significant improvements through renovations of key components:
- Comprehensive updates to Minio, Vault, Confluence, and External Secrets
- Successfully migrated Mattermost CI pipelines from built-in PostgreSQL to RDS DB
- Implementation of ESO cluster secret functionality

### Security and Compliance Advancement

- Completed renovate updates for Anchore Enterprise and Neuvector
- Internal testing of KubeScape project
- Refined Kyverno policy implementation
- Progress toward multi-cluster Twistlock deployment support

### Observability Improvements

- Successfully implemented Prometheus remote-write metrics to Mimir over Istio
- Completed updates to core monitoring tools including Loki, Grafana, and Fluentbit
- Advanced CI tracing tools integration with Alloy, Tempo, and Loki

### Service Mesh Developments

Significant progress has been made in service mesh functionality:
- Resolution of Tetrate image enabling in Sandbox Istio Gateway
- Advanced templating for public and passthrough gateway implementation
- Near completion of the Kiali labeling epic with only 13 remaining issues

## Edge Computing Innovation

- Advancement of initiatives toward the anticipated 1.0 release

## Community Engagement

We extend our gratitude to Daniel Dides and the entire Big Bang team for their valued contributions to this release. The success of Big Bang relies heavily on the engagement of our community, and we request feedback through the following methods:
- [Issue](https://repo1.dso.mil/big-bang/bigbang/-/issues/new) reporting on our platform
- Consulting our [comprehensive documentation](https://docs-bigbang.dso.mil/latest/) for implementation guidance
- Providing [feedback](https://join.slack.com/t/bigbanguniver-ft39451/shared_invite/zt-2mrtefxg6-5WJr85JD3NPbreMuAcQR0A) on new features and improvements

## Looking Forward

As we continue to evolve Big Bang, our focus remains on delivering robust, secure, and scalable solutions for enterprise deployment. The progress demonstrated in this release reflects our commitment to excellence and continuous improvement across all aspects of the platform.

For detailed information about the upgrade process and known issues, please consult the release notes in our documentation. We look forward to your feedback and continued collaboration in making Big Bang even better.

*Stay tuned for more updates as we continue to enhance and expand the capabilities of Big Bang.*