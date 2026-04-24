package main

# Demo rendered-set invariants for HelmRelease objects.
#
# Why this file exists:
# The existing helm unittest contract already proves Big Bang can enforce these
# metadata rules. This file demonstrates the narrower conftest claim: repo-wide
# rendered-object invariants read more cleanly as one categorical policy over a
# combined render than as many package-specific assertions.

# Keep the metadata contract intentionally small and obvious. The point of the
# demo is not to replace all testing, but to show that a single rule can span
# every rendered HelmRelease in the set.
required_labels := [
  "app.kubernetes.io/name",
  "app.kubernetes.io/managed-by",
  "app.kubernetes.io/part-of",
]

# This policy is meant to run with conftest --combine. In combined mode input is
# the full rendered document set, so we first project just the HelmReleases out
# of the manifest stream.
helmreleases contains hr if {
  some doc in input
  hr := doc.contents
  hr.kind == "HelmRelease"
}

# Cross-object checks are easier to express against a set of rendered names than
# by repeatedly scanning the manifest list. That keeps the later rules close to
# the human phrasing: "if X renders, Y must also render".
helmrelease_names contains hr_name if {
  some hr in helmreleases
  hr_name := name(hr)
}

# These helpers normalize how we read metadata so the rule bodies can focus on
# the contract rather than nil-check boilerplate.
labels(hr) := object.get(object.get(hr, "metadata", {}), "labels", {})

name(hr) := object.get(object.get(hr, "metadata", {}), "name", "<unnamed>")

# Treat missing and empty labels the same. For repo contracts there is no useful
# distinction between "not present" and "present but blank".
missing_required_label(hr, key) if {
  value := object.get(labels(hr), key, null)
  value == null
}

missing_required_label(hr, key) if {
  value := object.get(labels(hr), key, null)
  value == ""
}

# The baseline metadata contract mirrors the big repetitive helm unittest file,
# but says it once for the entire rendered class of objects.
invalid_messages contains message if {
  some hr in helmreleases
  some key in required_labels
  missing_required_label(hr, key)
  message := sprintf("HelmRelease %q missing required label %q", [name(hr), key])
}

# Keep the value check separate so failures explain whether the issue is missing
# metadata or the wrong shared ownership label.
invalid_messages contains message if {
  some hr in helmreleases
  object.get(labels(hr), "app.kubernetes.io/part-of", null) != "bigbang"
  message := sprintf(
    "HelmRelease %q has app.kubernetes.io/part-of=%v, want %q",
    [name(hr), object.get(labels(hr), "app.kubernetes.io/part-of", null), "bigbang"],
  )
}

# The next checks are the more interesting part of the demo. They are grounded
# in recent repo history where feature-flag fan-out and package relationships
# drifted. These rules sell why --combine matters: they reason about the full
# rendered set, not one object at a time.

# Ambient mode bugs recently showed that rendering ztunnel without the rest of
# the ambient stack is a bad state. Use rendered membership as the contract so
# the rule stays about the actual output, not about guessing which values led to
# that output.
invalid_messages contains message if {
  helmrelease_names["ztunnel"]
  not helmrelease_names["gateway-api"]
  message := sprintf(
    "HelmRelease set renders %q, so it must also render %q",
    ["ztunnel", "gateway-api"],
  )
}

invalid_messages contains message if {
  helmrelease_names["ztunnel"]
  not helmrelease_names["istio-cni"]
  message := sprintf(
    "HelmRelease set renders %q, so it must also render %q",
    ["ztunnel", "istio-cni"],
  )
}

# bbctl has had real dependency/enablement drift with monitoring. This kind of
# package-to-package relationship is awkward in helm unittest but straightforward
# once conftest sees the whole rendered set.
invalid_messages contains message if {
  helmrelease_names["bbctl"]
  not helmrelease_names["monitoring"]
  message := sprintf(
    "HelmRelease set renders %q, so it must also render %q",
    ["bbctl", "monitoring"],
  )
}

# Mattermost and Mattermost Operator have also drifted before. Keeping this rule
# explicit makes the demo about real repo mistakes, not invented graph theory.
invalid_messages contains message if {
  helmrelease_names["mattermost"]
  not helmrelease_names["mattermost-operator"]
  message := sprintf(
    "HelmRelease set renders %q, so it must also render %q",
    ["mattermost", "mattermost-operator"],
  )
}

# Conftest expects deny messages. Aggregating everything into invalid_messages
# keeps the output shape stable as we add or remove rendered-set invariants.
deny contains message if {
  some message in invalid_messages
}
