# Migration Guide

This section contains documentation related to migrating Big Bang deployments and configurations.

## Overview

Migration guides help you transition between versions, update configurations, or move deployments across environments. These documents provide step-by-step instructions and best practices for successful migrations.

For the 3.x-to-4.0 upgrade, **upgrade to 3.35.1 first**, then **upgrade to 4.0
with Ambient enabled and the unified package and `bb-common` values migrations
applied**. Start with the [4.0 upgrade checklist](migrating-to-bb4.0.md).
Custom Kyverno CEL policies and exceptions require separate review; the package
values migration script does not convert them or enable Ambient.

## Contents

- [Migrating from Big Bang 3.x to 4.0](migrating-to-bb4.0.md)
- [Migrating Istio for Big Bang 3.0](migrating-istio-for-bb3.0.md)
- [Migrating Istio Sidecar to Ambient](migrating-istio-to-ambient.md)
- [Migrating Package Values for Big Bang 4.0](migrating-package-values-for-bb4.0.md)
- [Package Values Migration Script Reference](package-values-migration-script.md)
- [Migrating Kyverno Policies for Big Bang 4.0](migrating-kyverno-policies-for-bb4.0.md)

## Getting Help

If you encounter issues during migration, please consult the main Big Bang documentation or reach out to the support channels listed in the project README.
