# Streamlining Integration with [`bb-common`](https://repo1.dso.mil/big-bang/product/packages/bb-common)

## Setting the Stage

Big Bang has always aimed to deliver a secure, ready-to-use Kubernetes platform
for the Department of Defense. But as the ecosystem has grown and new packages
have been added, one area has become a constant source of friction: **network
policies**.

Until now, each Big Bang package tended to define its own policies in slightly
different ways. The result? Inconsistency, duplication, and confusion — both for
contributors and for engineers trying to consume Big Bang downstream.

## The Problem with Inconsistency

- Different packages often modeled the same types of rules in different formats.
- Some components shipped with overly permissive defaults, while others were
  locked down in unexpected ways.
- Updates or fixes to a common rule meant repeating the same changes across
  multiple charts.

In short, we had a patchwork approach to network security — and that doesn’t
scale when you’re trying to deliver a coherent, secure-by-default platform.

## The Solution: `bb-common`

To fix this, we’ve introduced a new **library chart**,
[`bb-common`](https://repo1.dso.mil/big-bang/product/packages/bb-common),
designed specifically to handle network policy creation across all Big Bang
components.

Instead of each package rolling its own rules, they can now rely on a **single
shared implementation**:

- **Consistency:** Common patterns (like allowing monitoring traffic or
  inter-namespace communication) are implemented once and reused everywhere.
- **Security:** Default-deny policies are enforced uniformly, with clear,
  predictable overrides.
- **Maintainability:** Fixes and improvements only need to be made in one place.

## What This Means for Big Bang Users

For downstream engineers, `bb-common` means:

- Fewer surprises — policies will look and behave the same across all
  components.
- Simpler customization — shared shorthand syntax makes it easier to define
  exceptions without rewriting raw Kubernetes YAML.
- More confidence — you can trust that security boundaries are enforced the same
  way, no matter which packages you deploy.

## Looking Forward

This is just the first step. By consolidating network policy logic into
`bb-common`, we’ve set the stage for:

- Easier adoption of new security requirements.
- Faster iteration on best practices.
- A more stable, predictable Big Bang for everyone building on top of it.

---

### Call to Action

If you’re a Big Bang consumer or contributor, we encourage you to:

- Explore the [`bb-common` documentation](link-to-docs).
- Try out the new network policy framework in your environments.
- Provide feedback — we want to make this as seamless and powerful as possible.

---

Would you like me to **add in some example snippets** (like old vs. new YAML, or
shorthand vs. expanded policy) to make the post more concrete? That could really
drive home the before/after story.
