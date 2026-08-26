# Airgap w/Hauler

Big Bang releases ship `bb-<tag>-images-charts.tar.zst`, a
[Hauler](https://github.com/hauler-dev/hauler) content archive holding every
container image Big Bang needs plus the OCI-published Big Bang Helm charts. It is
an alternative to `images.tar.gz`, which remains available and unchanged.

Use this if your environment already has a registry (Harbor, Artifactory, Nexus,
or any OCI registry) to import into.

## Prerequisites

- The [`hauler` CLI](https://github.com/hauler-dev/hauler/releases) on the high side.
  Optional — see [Without the hauler CLI](#without-the-hauler-cli) if you cannot
  install it and would rather use `skopeo`.
- A registry you can push to, and credentials for it
- Roughly 2x the archive size in free disk for the unpacked store

## Import

Download `bb-<tag>-images-charts.tar.zst` and the release checksums file from
the [release page](https://repo1.dso.mil/big-bang/bigbang/-/releases).

The release page always lists the archive; on the rare release where it failed to
build, that link returns 404. Confirm the file actually appears in the checksums
manifest before trusting it — `--ignore-missing` reports success for a file it
never checked.

The archive is named for its release, so `-f` is required — `hauler store load`
on its own looks for hauler's default `haul.tar.zst` and will not find it.

```shell
grep images-charts bigbang-<tag>_checksums.txt
sha256sum -c bigbang-<tag>_checksums.txt --ignore-missing

hauler store load -f bb-<tag>-images-charts.tar.zst
hauler login <your-registry> -u <username> -p <password>
hauler store copy registry://<your-registry>
```

Hauler strips the source registry host and preserves the rest of the repository
path, so an image published as

```
registry1.dso.mil/ironbank/big-bang/base:2.1.0
```

lands in your registry as

```
<your-registry>/ironbank/big-bang/base:2.1.0
```

Set your Big Bang registry overrides to `<your-registry>` and the `ironbank/...`
paths resolve as published. If you are migrating from the older `images.tar.gz`
flow, compare a few entries against your current registry before switching over.

### Harbor

Harbor treats the first path segment as a **project** and will not create one
automatically. Create the projects matching the top-level path segments in
`images-v2-with-dependencies.txt` — at minimum `ironbank` and `bigbang` — before
running `hauler store copy`, or the pushes will fail with permission errors.

### Self-signed registry certificates

```shell
hauler store copy registry://<your-registry> --insecure
```

## Without the hauler CLI

The archive is not a proprietary format — it is a zstd-compressed tar of a standard
OCI image layout, so the archive can be unpacked and pushed with any OCI-aware
tooling if you cannot install `hauler` on the high side.

```shell
mkdir haul && tar --zstd -xf bb-<tag>-images-charts.tar.zst -C haul
```

That yields `index.json`, `manifest.json`, and `blobs/sha256/`. Note the layout does
not include an `oci-layout` marker file; tools that validate the layout strictly
will want one, and it is a single line to add:

```shell
printf '{"imageLayoutVersion":"1.0.0"}' > haul/oci-layout
```

Each image is addressable by the ref name recorded in `index.json`, so a push loop
is short. Refs repeat across entries (signatures and attestations share the name of
the image they cover), hence the `sort -u`:

```shell
jq -r '.manifests[].annotations."org.opencontainers.image.ref.name" | select(. != null)' \
  haul/index.json | sort -u \
  | xargs -P4 -I{} skopeo copy --retry-times 3 oci:haul:{} docker://<your-registry>/{}
```

Two notes if you go this route:

- `crane push` reads the layout but refuses a multi-image one without `--index`,
  which fuses every image into a single index rather than pushing them to separate
  repositories. Use `skopeo`, or `oras` for individual artifacts.
- The ref names in `index.json` have the source registry host stripped
  (`ironbank/big-bang/base:2.1.0`), which is what makes the push loop above land
  images at the right paths. If you need to know where an image originally came
  from, `manifest.json` retains the full original reference in its `RepoTags`.

## Verifying signatures

Hauler carries cosign signatures, attestations, and SBOMs alongside each image by
default, so they arrive in your registry as the usual `sha256-<digest>.sig`,
`.att`, and `.sbom` tags. Signature verification with `cosign` works against your
internal registry without reaching back to the source.

## What is not included

The archive contains images and OCI Helm charts only. If you deploy Big Bang
packages from **git** sources rather than the `helmRepo` (OCI) sources, you also
need `repositories.tar.gz` from the same release and a git server to host it.
Hauler has no git repository content type and does not replace that artifact.
