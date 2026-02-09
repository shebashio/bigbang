# k3d-dev.sh BATS Testing — Next Steps

## Sequence

### 1. First bigbang umbrella MR — land tests + lefthook config

Land real `.bats` files in the bigbang repo before wiring up CI so the Step 1 pipeline MR has something to run.

**Contents:**

```
tests/
└── bats/
    ├── helpers/
    │   └── setup.bash
    ├── k3d-dev/
    │   ├── argument_parsing.bats
    │   └── domain_config.bats
    └── README.md
```

**lefthook entry** (add to existing lefthook config or create):

```yaml
pre-push:
  commands:
    bats:
      glob: "tests/bats/**/*.bats"
      run: bats tests/bats/**/*.bats
```

Frame the MR as: "Adds developer-facing regression tests for k3d-dev.sh with local git hook. No CI changes."

### 2. Iterate on test coverage (subsequent small MRs, interleave with package work)

Each MR adds one `.bats` file. No pipeline changes, no process discussion.

- `tests/bats/k3d-dev/oidc_config.bats`
- `tests/bats/helpers/mock_aws.bash` + `tests/bats/helpers/bin/aws` (mock executable)
- `tests/bats/k3d-dev/aws_auth.bats`
- `tests/bats/k3d-dev/aws_ec2_lifecycle.bats`
- `tests/bats/helpers/mock_ssh.bash` (batch capture — overrides `batch_exec` to save scripts instead of executing)
- `tests/bats/k3d-dev/metallb_config.bats`
- `tests/bats/k3d-dev/batch_generation.bats`
- `tests/bats/k3d-dev/kubeconfig.bats`
- `tests/bats/k3d-dev/instructions.bats`

### 3. Step 1 MR to pipeline-templates — wire up CI

Once there are a dozen or so passing tests locally, submit the MR to add the `bats-test` component to `pipelines/bigbang.yaml`. Point at the existing tests and skip the allow-failure phase entirely.

```yaml
include:
  - '/library/templates.yaml'
  - component: $CI_SERVER_FQDN/big-bang/pipeline-templates/pipeline-templates/bats-test@master
    inputs:
      stage: "smoke tests"
      test_path: "tests/bats/"
```

MR description: "These tests have been running locally via lefthook. This moves them into CI."

### 4. Remove allow-failure gate (if used)

Once the suite is stable in CI, flip off allow-failure. Probably not needed if tests are already proven locally before CI is added.

---

## Folder Structure

```
tests/
└── bats/
    ├── README.md                           # conventions, how to run locally
    ├── helpers/
    │   ├── setup.bash                      # source k3d-dev.sh, reset globals
    │   ├── mock_aws.bash                   # configurable aws CLI mock
    │   ├── mock_ssh.bash                   # SSH/batch interception
    │   └── bin/
    │       └── aws                         # mock aws executable (dispatches on subcommand, returns fixture JSON)
    └── k3d-dev/
        ├── argument_parsing.bats           # flag parsing, mutual exclusion, validation
        ├── domain_config.bats              # PUBLIC_DOMAINS / PASSTHROUGH_DOMAINS generation
        ├── oidc_config.bats                # preset resolution, override precedence
        ├── kubeconfig.bats                 # path derivation from AWSUSERNAME/PublicIP/PROJECTTAG
        ├── aws_auth.bats                   # ARN parsing, username extraction, VPC/subnet validation
        ├── aws_ec2_lifecycle.bats          # instance discovery, destroy argument construction
        ├── aws_networking.bats             # security group lookup, EIP allocation
        ├── metallb_config.bats             # YAML generation for -m and -a modes
        ├── batch_generation.bats           # verify remote install scripts contain correct commands
        └── instructions.bats               # print_instructions output
```

**Rationale:**

- Flat-ish by script name (`k3d-dev/`) avoids the 6-deep mirror path (`tests/bats/docs/reference/scripts/developer/`) while keeping clear organization.
- Each `.bats` file gets a header comment linking back to the source file and function under test.
- When tests for other scripts (e.g. `install_flux.sh`) are added later, they get a sibling directory under `tests/bats/`.
- Shared helpers live in `helpers/` with a clear separation between setup code, mock definitions, and mock executables.
- The `bats-test` CI component's `test_path: "tests/bats/"` picks up everything automatically — no config changes needed as coverage grows.

---

## Response to Andrew on #912

Copy and paste the following:

---

Picking up the structure question — I'd go with a flat-ish layout under `tests/bats/` organized by script name:

```
tests/
└── bats/
    ├── README.md
    ├── helpers/
    │   ├── setup.bash
    │   ├── mock_aws.bash
    │   ├── mock_ssh.bash
    │   └── bin/
    │       └── aws
    └── k3d-dev/
        ├── argument_parsing.bats
        ├── domain_config.bats
        ├── oidc_config.bats
        └── ...
```

This avoids the 6-directory-deep mirror path while still making it obvious what's under test. Each `.bats` file gets a header comment pointing to the source file and functions it covers. When we add tests for other scripts later they get a sibling directory (e.g. `tests/bats/install-flux/`).

On the epic question — I'm going to keep this as the current issue. My plan is to land the actual `.bats` files in the bigbang repo first (with a lefthook config so they run locally on pre-push), then wire up the CI job in a follow-up once there are real tests to run against. That way the Step 1 pipeline MR has something concrete to validate against instead of a no-op.

First MR will be small: `helpers/setup.bash` + argument parsing and domain config tests for k3d-dev.sh. Pure function tests, no mocking needed, should be uncontroversial. I'll add coverage incrementally from there, interleaved with normal sprint work.

---
