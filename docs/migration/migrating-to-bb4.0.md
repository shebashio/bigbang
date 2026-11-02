# Migrating from Big Bang 3.x to 4.0

Follow this upgrade sequence for existing 3.x deployments:

1. **Upgrade to Big Bang 3.35.1.** Complete and validate that upgrade first.
2. **Upgrade from 3.35.1 to Big Bang 4.0 with Ambient enabled**, using the
   unified `packages.<name>` values format and migrated `bb-common` overrides.

Review the release notes for both releases, the target releases'
[Kubernetes and cluster prerequisites](../getting-started/prerequisites.md), and
the general [upgrade procedure](../operations/upgrades.md). Test the complete
sequence in a representative staging environment before production.

## Step 1: Upgrade to Big Bang 3.35.1

Upgrade the deployment to **3.35.1** using its existing values and mesh mode.
Review any intervening release notices and complete their required actions.
Wait for Flux reconciliation and package upgrades to finish, then verify
workload health, mission traffic, SSO, and policy enforcement before proceeding.

Use the configuration successfully deployed on 3.35.1 as the input for the
4.0 values migration. Keep the deployment on 3.35.1 while preparing that output.

## Step 2: Upgrade to Big Bang 4.0 with Ambient and migrated values

### Prepare the 4.0 configuration

Follow the [package values migration guide](migrating-package-values-for-bb4.0.md)
and run the migration utility with `--target 4` against the values deployed on
3.35.1. For one plaintext values file:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  --output values-4.x.yaml values.yaml
```

This converts legacy package paths to `packages.<name>` and migrates built-in
package overrides to the `bb-common` subchart layout, including the supported
legacy Istio and hardening migrations. Review script warnings and resolve any
settings requiring manual migration. Preserve the effective Helm or Flux order
when migrating layered values, patches, and Secrets.

In the primary migrated values file, explicitly enable Ambient and retain the
unified package contract:

```yaml
packageConfiguration:
  version: v1
istio:
  ambient:
    enabled: true
```

The migration script preserves the mesh setting supplied in its input; it does
not enable Ambient. Check later values sources for overrides of this setting.
Follow the [Ambient migration procedure](migrating-istio-to-ambient.md) to
prepare namespace enrollment, workload rollouts, and any temporary mixed-mode
settings needed during the 4.0 upgrade.

Review [Kyverno's CEL policy migration](migrating-kyverno-policies-for-bb4.0.md)
if you customize policies, parameters, exclusions, or exceptions. The values
migration script does not convert those policy definitions or settings.

### Deploy and verify

Render the complete configuration against the 4.0 chart, then deploy the
**4.0 version change, migrated values, and Ambient enablement together**.
Do not deploy `--target 4` output to 3.35.1 or any other 3.x release.

After reconciliation, verify package health, Ambient enrollment, mission
traffic, SSO, and policy enforcement. Complete the Ambient procedure's workload
rollouts and remove any temporary migration policies as directed by that guide.
