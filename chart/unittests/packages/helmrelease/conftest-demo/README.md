# Conftest demo: at-rest and post-render contracts

Big Bang already has a working `helm unittest` contract in
`chart/unittests/packages/helmrelease/metadata_contract_test.yaml`.

That file is the comparison artifact for this demo. It shows the tradeoff
clearly: `helm unittest` can enforce repo rules, but for generic contracts it
often does so through a long package-by-package assertion file. In this branch
that comparison file is about 990 lines. The post-render conftest policy says
the same core contract once and automatically covers future HelmReleases that
appear in the canonical render.

This folder shows two narrower `conftest` stories:

1. **At rest**: validate hand-authored scenario inputs before rendering
2. **Post-render**: validate repo-wide rendered-object invariants over a
   canonical wide render

This is not a `helm unittest` replacement.

Good fit:

- generic rules over hand-authored CI values files
- one or a few canonical wide renders
- cross-package rendered-set invariants
- failure messages aimed at humans

Weaker fit:

- cheap universal pre-commit checks for every possible config
- proving every Big Bang values permutation
- package-local template behavior that `helm unittest` already handles well

## Demo layout

```text
conftest-demo/
  README.md
  at-rest/
    test_values_contract.rego
  post-render/
    helmrelease_contract.rego
    all-enabled-demo-values.yaml
```

## At-rest demo

This is the cleaner complement-to-`helm unittest`.

`helm unittest` is good at rendered template assertions.

This demo shows that `conftest` is also useful before rendering, on
hand-authored scenario inputs like `tests/test-values.yaml`.

### Policy

```bash
chart/unittests/packages/helmrelease/conftest-demo/at-rest
```

### What it checks

- partial `addons.mattermost.database` config should fail
- `addons.mattermost.enterprise.enabled=true` requires exactly one of:
  - `enterprise.license`
  - `enterprise.existingSecret`
- package SSO config requires top-level `sso.url`

These are coherence checks over canonical CI inputs, not style lint.

### Why this is believable

Relevant history:

- `!7449` Mattermost external DB config  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7449
- `!7432` Keycloak external DB logic error  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7432
- `!7534` Mattermost existing secret vs inline license  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7534
- `!7140` Grafana SSO cleanup  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7140
- `!7163` Authservice wiring via shared SSO state  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7163
- `!7384` Vault SSO route cleanup  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7384

### Clean run

```bash
conftest test -p chart/unittests/packages/helmrelease/conftest-demo/at-rest tests/test-values.yaml
```

Expected:

```text
1 test, 1 passed, 0 warnings, 0 failures, 0 exceptions
```

### Demo 1: partial external database config

```bash
cp tests/test-values.yaml /tmp/test-values-bad-db.yaml
yq -i '.addons.mattermost.database.host = "db.example.internal"' /tmp/test-values-bad-db.yaml
conftest test -p chart/unittests/packages/helmrelease/conftest-demo/at-rest /tmp/test-values-bad-db.yaml
```

Expected:

```text
FAIL - /tmp/test-values-bad-db.yaml - main - addons.mattermost.database is partially configured; host, port, username, password, and database must be set together
```

### Demo 2: conflicting Mattermost enterprise license inputs

```bash
cp tests/test-values.yaml /tmp/test-values-bad-license.yaml
yq -i '.addons.mattermost.enterprise.enabled = true | .addons.mattermost.enterprise.license = "demo-license" | .addons.mattermost.enterprise.existingSecret = "mattermost-license"' /tmp/test-values-bad-license.yaml
conftest test -p chart/unittests/packages/helmrelease/conftest-demo/at-rest /tmp/test-values-bad-license.yaml
```

Expected:

```text
FAIL - /tmp/test-values-bad-license.yaml - main - addons.mattermost.enterprise should set only one of enterprise.license or enterprise.existingSecret
```

### Demo 3: package SSO without global SSO base config

```bash
cp tests/test-values.yaml /tmp/test-values-bad-sso.yaml
yq -i 'del(.sso.url)' /tmp/test-values-bad-sso.yaml
conftest test -p chart/unittests/packages/helmrelease/conftest-demo/at-rest /tmp/test-values-bad-sso.yaml
```

Expected first failure:

```text
FAIL - /tmp/test-values-bad-sso.yaml - main - kiali.sso uses package SSO config, but top-level sso.url is missing
```

What actually happens:
- this reports every package-level SSO stanza that now lacks the shared global
  base URL

Why that is good:
- one broken global edit shows blast radius immediately
- the output teaches you which packages depend on the shared SSO base config

## Post-render demo

This is the stronger `--combine` story.

For repo-wide rendered-object invariants over a canonical render,
`conftest --combine` can express the contract more cleanly than a large
package-by-package assertion file.

### Policy

```bash
chart/unittests/packages/helmrelease/conftest-demo/post-render
```

### What it checks

#### Baseline metadata contract

Every rendered `HelmRelease` must have:

- `app.kubernetes.io/name`
- `app.kubernetes.io/managed-by`
- `app.kubernetes.io/part-of`

And:

- `app.kubernetes.io/part-of` must equal `bigbang`

#### Rendered-set consistency checks

- if `ztunnel` renders, `gateway-api` must also render
- if `ztunnel` renders, `istio-cni` must also render
- if `bbctl` renders, `monitoring` must also render
- if `mattermost` renders, `mattermost-operator` must also render

These are cross-object checks over the rendered set.

### Why this is believable

Relevant history:

- `!7651` Add common labels to all rendered helmreleases  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7651
- `!7576` Add toggle to enable ambient packages  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7576
- `!7598` Honor global ambient flag for integrated packages  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7598
- `!7487` Add istio-cni conditional dependency  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7487
- `!6376` `bbctl` requires `monitoring`  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/6376
- `!6369` `bbctl` dependency conditionals  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/6369
- `!7420` Mattermost requires Mattermost Operator  
  https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7420

### Why `--combine` matters

Without `--combine`, `conftest` evaluates one rendered document at a time.
That works, but the human-facing output is bad. `-o table` becomes a wall of
`SUCCESS`.

With `--combine`, `conftest` evaluates the rendered set once:

- one render
- one repo-wide contract check
- one pass result
- sharp failures for cross-object drift

### Canonical render

`post-render/all-enabled-demo-values.yaml` turns on the optional packages used
for this rendered-set demo. Today that render produces 47 `HelmRelease`
objects.

That is the important property of this demo. The policy does not enumerate 47
packages by name. It finds rendered `HelmRelease` objects and applies the
contract to the whole set.

### Clean run

```bash
helm template bigbang chart -f chart/unittests/packages/helmrelease/conftest-demo/post-render/all-enabled-demo-values.yaml > /tmp/bigbang-rendered.yaml
conftest test --combine -p chart/unittests/packages/helmrelease/conftest-demo/post-render /tmp/bigbang-rendered.yaml
```

Expected:

```text
1 test, 1 passed, 0 warnings, 0 failures, 0 exceptions
```

### Optional: show the HelmReleases under test

```bash
yq -r -N 'select(.kind == "HelmRelease") | .metadata.name' /tmp/bigbang-rendered.yaml
```

```bash
yq -r -N 'select(.kind == "HelmRelease") | .metadata.name' /tmp/bigbang-rendered.yaml | wc -l
```

### Demo 1: break the metadata contract

```bash
cp /tmp/bigbang-rendered.yaml /tmp/bigbang-rendered-bad.yaml
yq -i 'del(select(.kind == "HelmRelease" and .metadata.name == "alloy").metadata.labels."app.kubernetes.io/name")' /tmp/bigbang-rendered-bad.yaml
conftest test --combine -p chart/unittests/packages/helmrelease/conftest-demo/post-render /tmp/bigbang-rendered-bad.yaml
```

Expected:

```text
FAIL - Combined - main - HelmRelease "alloy" missing required label "app.kubernetes.io/name"
```

### Demo 2: break a rendered-set relationship

```bash
cp /tmp/bigbang-rendered.yaml /tmp/bigbang-rendered-bad.yaml
yq -i 'del(select(.kind == "HelmRelease" and .metadata.name == "monitoring"))' /tmp/bigbang-rendered-bad.yaml
conftest test --combine -p chart/unittests/packages/helmrelease/conftest-demo/post-render /tmp/bigbang-rendered-bad.yaml
```

Expected:

```text
FAIL - Combined - main - HelmRelease set renders "bbctl", so it must also render "monitoring"
```

### Optional: ambient-stack failure

```bash
cp /tmp/bigbang-rendered.yaml /tmp/bigbang-rendered-bad.yaml
yq -i 'del(select(.kind == "HelmRelease" and .metadata.name == "gateway-api"))' /tmp/bigbang-rendered-bad.yaml
conftest test --combine -p chart/unittests/packages/helmrelease/conftest-demo/post-render /tmp/bigbang-rendered-bad.yaml
```

Expected:

```text
FAIL - Combined - main - HelmRelease set renders "ztunnel", so it must also render "gateway-api"
```

## What this proves

Not:

- that `conftest` should replace `helm unittest`
- that one canonical render covers every Big Bang permutation
- that this should be the only test layer

Yes:

- `conftest` can validate hand-authored scenario inputs directly
- `conftest --combine` can validate repo-wide rendered-object invariants
- the rendered policy is shorter because it works at the object-class level,
  not the package-by-package level
- the rendered policy automatically covers future HelmReleases that appear in
  the canonical render
- Rego is a good fit for generic contracts that cut across package boundaries
- this is a believable complement to `helm unittest`
