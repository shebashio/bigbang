package main

# Demo values-file invariants for canonical CI scenarios like tests/test-values.yaml.
# These complement rendered-output checks by validating hand-authored scenario
# inputs before the chart is rendered.
#
# Why this file exists:
# The rendered HelmRelease demo proves conftest can express repo-wide contracts
# over output. This file proves the complementary case: conftest can also catch
# bad scenario inputs before we spend time rendering anything.

# We normalize "present" to mean non-null and non-empty because these test
# values files use empty strings as the default unset state for most fields.
nonempty(value) if {
  value != null
  value != ""
}

# These helpers let the rule bodies read like the actual contract: some fields
# were provided vs all required fields were provided.
any_nonempty(values) if {
  some value in values
  nonempty(value)
}

all_nonempty(values) if {
  every value in values {
    nonempty(value)
  }
}

# SSO bugs in this repo often come from two slightly different shapes:
# packages may set enabled=true, or they may only populate client_id in the
# scenario file and rely on downstream defaults. Treat either shape as "this
# package intends to use SSO" so the policy catches both.
uses_sso(config) if {
  object.get(config, "enabled", false)
}

uses_sso(config) if {
  nonempty(object.get(config, "client_id", ""))
}

# Start with Mattermost because recent fixes in repo history showed two real
# error modes there: partial external database config and conflicting enterprise
# license inputs. Keeping the first values-demo focused on one package makes the
# rules easier to explain live.
mattermost_db := object.get(object.get(object.get(input, "addons", {}), "mattermost", {}), "database", {})
mattermost_enterprise := object.get(object.get(object.get(input, "addons", {}), "mattermost", {}), "enterprise", {})

# Package-level SSO settings depend on this shared top-level issuer base. When a
# bad edit removes it, multiple package configs quietly become nonsensical. That
# is exactly the kind of scenario-level drift this demo wants to surface.
global_sso_url := object.get(object.get(input, "sso", {}), "url", "")

# Use an explicit allowlist instead of crawling the document dynamically. That
# keeps the demo honest: we are checking the package SSO shapes we actually saw
# repeated in test-values.yaml and recent bugfixes, not pretending to infer a
# full schema from arbitrary YAML.
package_sso_entries := [
  {"path": "kiali.sso", "config": object.get(object.get(input, "kiali", {}), "sso", {})},
  {"path": "grafana.sso", "config": object.get(object.get(input, "grafana", {}), "sso", {})},
  {"path": "neuvector.sso", "config": object.get(object.get(input, "neuvector", {}), "sso", {})},
  {"path": "twistlock.sso", "config": object.get(object.get(input, "twistlock", {}), "sso", {})},
  {"path": "addons.argocd.sso", "config": object.get(object.get(object.get(input, "addons", {}), "argocd", {}), "sso", {})},
  {"path": "addons.anchoreEnterprise.sso", "config": object.get(object.get(object.get(input, "addons", {}), "anchoreEnterprise", {}), "sso", {})},
  {"path": "addons.fortify.sso", "config": object.get(object.get(object.get(input, "addons", {}), "fortify", {}), "sso", {})},
  {"path": "addons.gitlab.sso", "config": object.get(object.get(object.get(input, "addons", {}), "gitlab", {}), "sso", {})},
  {"path": "addons.mattermost.sso", "config": object.get(object.get(object.get(input, "addons", {}), "mattermost", {}), "sso", {})},
  {"path": "addons.sonarqube.sso", "config": object.get(object.get(object.get(input, "addons", {}), "sonarqube", {}), "sso", {})},
  {"path": "addons.vault.sso", "config": object.get(object.get(object.get(input, "addons", {}), "vault", {}), "sso", {})},
]

# Partial DB config is a high-value check because it is easy to create with a
# one-line edit and hard to notice in review. We enforce all-or-nothing here so
# that CI fails on the values file before rendering produces a more obscure
# package-specific failure.
invalid_messages contains message if {
  fields := [
    object.get(mattermost_db, "host", ""),
    object.get(mattermost_db, "port", ""),
    object.get(mattermost_db, "username", ""),
    object.get(mattermost_db, "password", ""),
    object.get(mattermost_db, "database", ""),
  ]
  any_nonempty(fields)
  not all_nonempty(fields)
  message := "addons.mattermost.database is partially configured; host, port, username, password, and database must be set together"
}

# Enterprise license input has two supported paths: inline license material for
# simple dev/test scenarios, or an existing secret for safer externalized input.
# Enabling enterprise with neither option is almost certainly a mistake.
invalid_messages contains message if {
  object.get(mattermost_enterprise, "enabled", false)
  license := object.get(mattermost_enterprise, "license", "")
  existing_secret := object.get(mattermost_enterprise, "existingSecret", "")
  not nonempty(license)
  not nonempty(existing_secret)
  message := "addons.mattermost.enterprise.enabled=true requires either enterprise.license or enterprise.existingSecret"
}

# Setting both inputs at once is also suspicious because it hides the source of
# truth. Rejecting that keeps the scenario file unambiguous and mirrors the repo
# history around existingSecret-vs-inline drift.
invalid_messages contains message if {
  object.get(mattermost_enterprise, "enabled", false)
  license := object.get(mattermost_enterprise, "license", "")
  existing_secret := object.get(mattermost_enterprise, "existingSecret", "")
  nonempty(license)
  nonempty(existing_secret)
  message := "addons.mattermost.enterprise should set only one of enterprise.license or enterprise.existingSecret"
}

# This rule intentionally fans out to every affected package. One broken global
# SSO edit should show blast radius, not a single representative failure. That
# makes the demo stronger for humans and better reflects what actually went
# wrong in the scenario file.
invalid_messages contains message if {
  some entry in package_sso_entries
  uses_sso(entry.config)
  not nonempty(global_sso_url)
  message := sprintf("%s uses package SSO config, but top-level sso.url is missing", [entry.path])
}

# Conftest expects deny messages. Keeping all rule-specific failures in the
# invalid_messages set makes it easy to add more scenario contracts later
# without changing the output shape of this demo.
deny contains message if {
  some message in invalid_messages
}
