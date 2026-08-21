# Big Bang 4.0 Blog Outline

> Working outline. This post should describe the capabilities delivered by the
> Big Bang value stream leading up to 4.0, not only the changes attached to the
> `4.0.0` Git tag.

## Working title

**Big Bang 4.0: A Simpler, More Consistent Platform for Secure Kubernetes**

Alternative titles:

- **Big Bang 4.0: The Next Evolution of the Platform**
- **What We Have Been Building: Big Bang 4.0**
- **Big Bang 4.0: Less Platform Friction, More Mission Focus**

## Core message

Big Bang 4.0 represents the result of sustained work across the 3.x lifecycle to
make secure Kubernetes platforms easier to operate, extend, test, and deliver.
The major version gives us an opportunity to bring those related improvements
together into one story and explain their value to platform teams and mission
owners.

This should be a capability-focused post, not an exhaustive release note. Link
to migration guides, release notes, ADRs, and the existing deep-dive blog posts
for implementation details.

## Intended audience

- Existing Big Bang operators planning for 4.0
- Platform engineering and SRE teams evaluating Big Bang
- Mission application teams that consume services provided by Big Bang
- Program and technical leaders who need to understand the value delivered

## Proposed narrative

### 1. Introduction: 4.0 is more than a tag

- Briefly position 4.0 as the next major milestone after Big Bang 3.0.
- Explain that many of these capabilities were developed, tested, or made
  available incrementally during the 3.x lifecycle.
- Set expectations: this article highlights outcomes; a separate migration
  guide or breaking-changes post will contain upgrade actions.
- Lead with the user benefit: less operational overhead, more consistent
  configuration, and a stronger foundation for secure platform delivery.

**Details needed:** target release date, current 4.0 status, and whether we want
to name a small set of top-level value-stream goals in the opening.

### 2. A simpler service mesh with Istio Ambient Mode

**Headline:** Move the service mesh data plane away from a sidecar in every pod
and toward shared node-level `ztunnel` proxies.

- Connect the story to the operatorless Istio work highlighted in Big Bang 3.0.
- Note that Ambient support became available as an opt-in beta in Big Bang 3.23.
- Explain the high-level benefits:
  - lower per-workload proxy overhead;
  - application pods no longer need to restart for routine proxy updates;
  - easier onboarding of workloads into the mesh;
  - selective Layer 7 capabilities through waypoint proxies when needed.
- Describe the supporting platform work at a high level: Istio CNI, `ztunnel`,
  Gateway API, HBONE-aware network policies, and Layer 4 authorization policies.
- Point readers to the Ambient beta post and the migration guide.

**Confirm before drafting:** Will Ambient be enabled by default in 4.0? What is
the production-support status of waypoint proxies and Authservice integrations?
Do we have measured resource savings or a customer example we can publish?

### 3. One consistent way to configure packages

**Headline:** Make built-in and additional packages feel like parts of one
coherent platform.

- Introduce the canonical `packages.<name>` configuration model.
- Explain the user problem it solves: package settings have historically been
  split between top-level keys, `addons`, and the additional-package model.
- Describe the outcome:
  - a more predictable location for package configuration;
  - clearer package identity and naming;
  - a smoother path for extending Big Bang with mission-specific packages;
  - less special-case knowledge for platform operators and automation.
- Mention the 3.x opt-in compatibility path and clearly summarize what changes
  in 4.0.
- Use one small before/after values example in the final article.

**Confirm before drafting:** Is canonical `packages.<name>` configuration a 4.0
default or requirement? Which legacy paths are removed, and what migration or
validation tooling will users have?

### 4. Reusable, secure-by-default integration with `bb-common`

**Headline:** Standardize common platform integration instead of implementing
the same security and operational patterns separately in every package.

- Summarize the initial network-policy use case for the `bb-common` hybrid
  library chart.
- Emphasize benefits already described in the dedicated blog post:
  consistency, default-deny behavior, maintainability, testability, flexibility,
  and auditability.
- Explain how its adoption across packages supports Ambient Mode and reduces
  one-off integration logic.
- Describe any cross-cutting capabilities added beyond network policies, such
  as common labels, namespaces, image pull secrets, service entries, monitoring,
  or authorization policy—only after confirming final 4.0 scope.
- Link to the `bb-common` deep dive instead of reproducing its DSL examples.

**Details needed:** package adoption numbers, which shared capabilities are
production-ready, and one concrete example of effort or risk reduced.

### 5. Better artifacts for air-gapped and controlled environments

**Headline:** Make software dependencies explicit, precise, and easier to
approve or pre-stage.

- Describe the move from discovering images by scraping a running cluster to
  declaring image metadata explicitly.
- Explain the new dependency-aware `images-v2-*` artifacts in user terms:
  operators can identify, allowlist, and pre-pull the images their deployment
  actually needs.
- Highlight that the established `images.txt` workflow remains available.
- Connect the work to supply-chain clarity, repeatability, and air-gap planning.
- Include the documented delivery improvement: the release pipeline dropped
  from multiple hours to approximately 20 minutes after redundant umbrella
  smoke-test jobs were removed in favor of package-level testing.

**Confirm before drafting:** Is the approximately 20-minute figure still
representative, and are there downstream/customer results we can cite?

### 6. Faster feedback and greater confidence in delivery

**Headline:** Improve how changes are developed, tested, and promoted—not just
what is deployed into customer clusters.

- Group the value-stream improvements that shorten feedback loops and reduce
  regressions, potentially including:
  - expanded Helm unit-test coverage for umbrella and package behavior;
  - reusable package-level test configuration and Cypress coverage;
  - on-demand/local K3d development workflows;
  - explicit Flux behavior and improved install/upgrade validation;
  - automated documentation or release-artifact validation.
- Focus on outcomes: earlier defect detection, more repeatable changes, safer
  upgrades, and less time waiting for release validation.
- Include one or two measurable results rather than a long list of internal
  tooling changes.

**Details needed:** Which delivery improvements does the value stream most want
to highlight? What metrics can be shared (pipeline time, deployment time,
regression rate, test coverage, or engineering hours saved)?

### 7. Optional capability spotlight: unified telemetry with Grafana Alloy

Include this as a full section only if it is a major part of the intended 4.0
story.

- Recap the transition from Promtail to Grafana Alloy for log collection.
- Highlight newer work that expands Alloy toward metrics and trace collection.
- Explain the user value of a consistent OpenTelemetry-compatible collection
  layer for logs, metrics, and traces.
- Clarify which capabilities are defaults, supported options, or still being
  developed.

**Confirm before drafting:** What is complete for 4.0, what becomes the default,
and does any legacy collector reach end of support?

### 8. What 4.0 means for current users

- Separate capabilities from required migration actions.
- Provide a short table in the final article:

  | Area | User benefit | Action required |
  | --- | --- | --- |
  | Ambient Mode | Lower mesh overhead and simpler workload onboarding | TBD |
  | Package configuration | One predictable package model | TBD |
  | `bb-common` | Consistent security integration | TBD |
  | Image metadata | More precise air-gap inputs | None/TBD |

- Link to the 4.0 release notes, breaking-changes list, and migration guides.
- State the supported Kubernetes versions and any notable package lifecycle
  changes only after the release scope is finalized.

### 9. Closing: built with the community

- Reiterate the outcome: Big Bang 4.0 reduces platform friction so teams can
  spend more time on mission applications.
- Thank contributors, beta testers, customers, and community members whose
  feedback shaped these capabilities.
- Add current calls to action: evaluate the release, read the migration guide,
  attend the BBTOC/briefing, and join the community discussion channels.

**Details needed:** approved contact links, briefing date, beta/early adopter
acknowledgements, and any named teams or contributors to recognize.

## Suggested supporting material

- A simple sidecar-versus-Ambient architecture graphic
- One before/after package configuration snippet
- One image dependency graph or air-gap artifact example
- Two or three outcome metrics presented as callouts
- Links to:
  - `blog/istio-ambient-beta.md`
  - `blog/streamlining-integration-with-bb-common.md`
  - `blog/images-v2-metadata-files.md`
  - the 4.0 migration and breaking-change documentation

## Decisions needed before writing the first draft

1. Which four or five capabilities are the official value-stream highlights?
2. Which changes are true 4.0 defaults or breaking changes, versus capabilities
   delivered earlier in 3.x?
3. What measurable outcomes or user stories can be shared publicly?
4. Should the tone be a release announcement, an engineering retrospective, or
   a product/value narrative? The outline currently favors a product/value
   narrative.
5. Should migration details live in this post or in a separate companion post?
6. What release date, event, and community contact information should appear?
