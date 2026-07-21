# Migrating package values for Big Bang 4.0

Big Bang 4.0 consolidates built-in and user-supplied package configuration under `packages.<name>`. Big Bang 3.x accepts both the old and new paths so you can migrate values before upgrading.

Run the migration script with [Mike Farah yq v4](https://github.com/mikefarah/yq) installed:

```shell
scripts/migrate-values-3-to-4.sh values.yaml > values-4.x.yaml
```

You can also select an output file explicitly:

```shell
scripts/migrate-values-3-to-4.sh --output values-4.x.yaml values.yaml
```

To replace the input, use `--in-place`. This mode first creates `values.yaml.bak` and refuses to overwrite an existing backup:

```shell
scripts/migrate-values-3-to-4.sh --in-place values.yaml
```

The script moves known top-level built-in packages and packages under `addons` into the unified map. Existing custom packages and unrelated values are preserved. If both the legacy and unified paths configure a package, their maps are recursively merged and `packages.<name>` takes precedence, matching Big Bang 3.x compatibility behavior.

For example:

```yaml
# Before
monitoring:
  enabled: true
addons:
  gitlab:
    enabled: false
packages:
  podinfo:
    enabled: true
```

becomes:

```yaml
# After
packages:
  monitoring:
    enabled: true
  gitlab:
    enabled: false
  podinfo:
    enabled: true
```

Review the output and render it with the 3.x chart before adopting it. Because the migration is supported by 3.x, you can commit and deploy the migrated values independently of the 4.0 chart upgrade.

```shell
helm template bigbang ./chart -f values-4.x.yaml > /dev/null
```

The script is idempotent: after all known legacy paths have moved, running it again leaves the values unchanged.
