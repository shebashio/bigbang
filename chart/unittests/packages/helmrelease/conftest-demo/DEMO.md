# Conftest demo: at-rest and post-render checks

Big Bang already has a working `helm unittest` contract in
`chart/unittests/packages/helmrelease/metadata_contract_test.yaml`.

That file is the comparison artifact for this exploration. It shows the tradeoff
pretty clearly: `helm unittest` can enforce repo rules, but for generic
contracts it often does so through a long package-by-package assertion file.

This folder is not a proposal to replace `helm unittest`.

It is just a field report on two places where `conftest` plus a small amount of
Rego seems worth trying:

1. **At rest**: check hand-authored scenario inputs before rendering
2. **Post-render**: when all Big Bang packages are enabled, check the rendered
   output for missing compatibility requirements across packages

I am not claiming this should definitely be added to Big Bang. This is mainly a
small exploration to see where this workflow feels natural and where it does
not.

## Demo layout

```text
conftest-demo/
  DEMO.md
  at-rest/
    test_values_contract.rego
  post-render/
    helmrelease_contract.rego
    all-enabled-demo-values.yaml
```

## Where each tool seems to fit

### `helm unittest`

Seems best for:

- package-local template behavior
- narrow assertions close to the chart code
- cases where the rendered snippet itself is the thing under test

Gets awkward when:

- the same rule should apply to every rendered `HelmRelease`
- the check spans multiple packages
- the assertions turn into a long enumerated file that has to stay in sync by
  hand

### JSON Schema

Seems best for:

- values-file shape
- required fields
- allowed keys
- simple `oneOf` and `if/then` structure checks

Gets awkward when:

- the rule is really about cross-package meaning, not local shape
- one top-level setting needs to fan out across a lot of package paths
- the logic would turn into a giant conditional tree inside one big schema file

### `conftest` + Rego

Seems best for:

- semantic checks over hand-authored scenario inputs
- rendered-set checks after `helm template` in an all-packages scenario
- cross-package compatibility rules that do not have a natural home in one
  package test

Gets awkward when:

- the rule is simple enough that schema already handles it cleanly
- the test needs to prove every possible Big Bang combination
- the check is really a package-local template unit test in disguise

## At-rest demo

This is the cleaner complement-to-`helm unittest`.

`helm unittest` is good at rendered template assertions.

This demo checks whether a canonical scenario file like `tests/test-values.yaml`
even makes sense before we spend time rendering the chart.

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

These are configuration-coherence checks, not style lint.

### Why these examples were chosen

They line up with real bug families we have already fixed:

- partial external database settings created invalid package config and had to be
  tightened up for Mattermost and Keycloak
  ([!7449](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7449),
  [!7432](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7432))
- inline license material and `existingSecret` needed a clearer source-of-truth
  rule for Mattermost
  ([!7534](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7534))
- package-level SSO assumptions drifted from shared top-level SSO wiring across
  Grafana, Authservice, and Vault
  ([!7140](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7140),
  [!7163](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7163),
  [!7384](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7384))

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

That fan-out is part of the value here. One bad top-level edit shows its blast
radius right away.

## Post-render demo

This is the more integration-ish demo.

When all Big Bang packages are enabled, `conftest --combine` lets us check the
rendered output for missing compatibility requirements across packages.

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

#### Rendered-set compatibility checks

- if `ztunnel` renders, `gateway-api` must also render
- if `ztunnel` renders, `istio-cni` must also render
- if `bbctl` renders, `monitoring` must also render
- if `mattermost` renders, `mattermost-operator` must also render

These are cross-object checks over the rendered set.

### Why these examples were chosen

They line up with real fixes we have already made:

- some rendered HelmReleases were missing the shared metadata labels entirely,
  and those gaps had to be fixed by hand
  ([!7651](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7651))
- ambient mode introduced a class of bugs where enabling one part of the stack
  did not consistently bring in the rest
  ([!7576](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7576),
  [!7598](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7598),
  [!7487](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7487))
- `bbctl` and `monitoring` drifted apart even though the package only makes
  sense when monitoring is present
  ([!6376](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/6376),
  [!6369](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/6369))
- Mattermost and Mattermost Operator drifted apart and had to be manually wired
  back together
  ([!7420](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/7420))

### Why `--combine` matters

Without `--combine`, `conftest` evaluates one rendered document at a time.
That works, but the output is noisy. `-o table` turns into a wall of `SUCCESS`.

With `--combine`, `conftest` evaluates the rendered set once:

- one render
- one repo-wide check
- one pass result
- direct failures for cross-package drift

### Canonical render

`post-render/all-enabled-demo-values.yaml` turns on the optional packages used
for this demo. Today that render produces 47 `HelmRelease` objects.

That is the useful property here. The policy does not enumerate 47 packages by
name. It finds rendered `HelmRelease` objects and applies the contract to the
whole set.

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

## What this suggests

This still looks more like a complement than a replacement.

The at-rest checks are the cleaner story if the goal is catching bad scenario
inputs before render time.

The post-render checks are the cleaner story if the goal is catching
cross-package drift when Big Bang is rendered in a wide, integration-heavy
shape.

The tradeoff is pretty straightforward:

- Some generic cross-package rules are easier to read in Rego than in a long
  package-by-package `helm unittest` file.
- `conftest --combine` automatically covers newly added rendered
  `HelmRelease` objects in the all-packages scenario.
- Some at-rest checks are probably better handled in JSON Schema than Rego.
- The rendered-set checks depend on an all-packages scenario, which is useful
  but still not the same thing as proving every supported combination.
- Rego is one more language to carry, and `conftest` is one more tool to wire
  into a repo that already has a lot of test freight.

So the open questions feel less like "can this work?" and more like:

- Are there enough recurring cross-package mistakes to justify another test
  layer?
- Would a few schema improvements cover most of the at-rest side more cheaply?
- Is one all-packages scenario enough to be worth checking in CI?
- Would this replace enough brittle existing test code to pay for itself?
