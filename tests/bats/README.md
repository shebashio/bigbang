# BATS Tests for Big Bang Developer Scripts

Unit tests for shell scripts under `docs/reference/scripts/developer/`.

## Running locally

```bash
# Install bats-core (macOS)
brew install bats-core

# Install bats-core (Ubuntu)
sudo apt install bats

# Run all tests
bats tests/bats/**/*.bats

# Run a specific test file
bats tests/bats/k3d-dev/argument_parsing.bats

# Verbose output
bats --verbose-run tests/bats/k3d-dev/argument_parsing.bats
```

## Structure

```
tests/bats/
├── helpers/
│   ├── setup.bash         # shared setup: source k3d-dev.sh, reset globals
│   ├── mock_aws.bash      # configurable aws CLI mock + assertions
│   ├── mock_ssh.bash      # SSH/batch interception + assertions
│   └── bin/
│       └── aws            # mock aws executable (returns fixture JSON)
├── fixtures/
│   └── aws_auth/          # JSON fixtures for AWS API responses
├── k3d-dev/
│   ├── argument_parsing.bats
│   ├── domain_config.bats
│   └── ...
└── README.md
```

## Conventions

- Each `.bats` file has a header comment linking to the source file and functions under test
- Test names follow: `"[context]: [expected behavior]"`
- Tests must not call real AWS APIs, SSH to hosts, or create clusters
- Each test file is independently runnable
- Tests must pass on both Linux (CI) and macOS (developer workstations)

## Adding tests for a new script

1. Create a new directory under `tests/bats/` matching the script name
2. Add `.bats` files organized by functional area
3. Add any needed fixtures under `tests/bats/fixtures/`
4. The CI job automatically picks up any `.bats` files under `tests/bats/`
