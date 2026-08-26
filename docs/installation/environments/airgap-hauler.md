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

## Deploying Big Bang from the archive

Getting the archive into your registry is only half the job. Big Bang will not use it
until you tell it to, and **images and charts reach the registry by two different
routes**. Getting this wrong is the most common failure, so it is worth understanding
before copying any YAML:

| | Fetched by | Configured with |
|---|---|---|
| **Images** | kubelet/containerd, per node | admission-time rewriting, or a registry mirror |
| **Charts** | Flux source-controller, over HTTP | Big Bang **values** |

Neither substitutes for the other.

> **`registryCredentials` does not rewrite image references.** It only builds the
> imagePullSecret. Setting `registryCredentials.registry` to your registry will not move
> a single image pull, and the pods will sit in `ImagePullBackOff` while every rendered
> manifest looks correct.

### Images: rewrite at admission (recommended)

`MutatingAdmissionPolicy` is stable and enabled by default in **Kubernetes 1.36+**. It
runs inside the API server, so there is no webhook to operate and no policy engine to
install, and it rewrites at pod admission — which is downstream of *every* way an image
reference is produced, including istio sidecar injection and operator-spawned pods.

```yaml
apiVersion: admissionregistration.k8s.io/v1   # v1beta1 on Kubernetes 1.34-1.35
kind: MutatingAdmissionPolicy
metadata:
  name: rewrite-image-registry
spec:
  matchConstraints:
    resourceRules:
      - apiGroups: [""]
        apiVersions: ["v1"]
        operations: ["CREATE"]
        resources: ["pods"]
  failurePolicy: Fail
  # Required. Sidecars are injected by another webhook after this policy first runs;
  # without IfNeeded the injected containers are never rewritten.
  reinvocationPolicy: IfNeeded
  variables:
    - name: src
      expression: '"registry1.dso.mil/"'
    - name: dst
      expression: '"registry.example.mil/"'
  mutations:
    - patchType: ApplyConfiguration
      applyConfiguration:
        expression: >
          Object{
            spec: Object.spec{
              containers: object.spec.containers.map(c,
                Object.spec.containers{
                  name: c.name,
                  image: c.image.startsWith(variables.src)
                    ? variables.dst + c.image.substring(size(variables.src))
                    : c.image
                })
            }
          }
    - patchType: ApplyConfiguration
      applyConfiguration:
        expression: >
          Object{
            spec: Object.spec{
              initContainers: object.spec.?initContainers.orValue([]).map(c,
                Object.spec.initContainers{
                  name: c.name,
                  image: c.image.startsWith(variables.src)
                    ? variables.dst + c.image.substring(size(variables.src))
                    : c.image
                })
            }
          }
---
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingAdmissionPolicyBinding
metadata:
  name: rewrite-image-registry
spec:
  policyName: rewrite-image-registry
  matchResources:
    namespaceSelector: {}
```

Keep the `startsWith` guard. It confines the rewrite to Big Bang images and leaves the
cluster's own components — cloud CNI plugins, CoreDNS, kube-proxy — untouched.

**Apply the policy before anything else.** The rule matches `CREATE` only, so it never
touches pods that already exist, and a pod admitted before the policy is in place keeps
its original reference and fails to pull. Kubernetes does not re-admit pods, so that pod
stays broken until its owner recreates it. The order is:

```shell
# 1. create the cluster
# 2. apply the policy
kubectl apply -f rewrite-image-registry.yaml
# 3. install Flux from base/flux -- its manifests still say registry1.dso.mil
# 4. install Big Bang
```

Because the policy is live first, Flux's own controllers are rewritten as they are
admitted. Nothing needs pre-rewriting, including `base/flux`.

#### On Kubernetes 1.34 and 1.35

The feature exists but is beta and off by default. **Both** API-server flags are needed,
and they fail differently:

```
--runtime-config=admissionregistration.k8s.io/v1beta1=true
--feature-gates=MutatingAdmissionPolicy=true
```

With only the first, the API accepts the policy and `kubectl get mutatingadmissionpolicy`
reports it live with `MUTATIONS: 2` — and it silently rewrites nothing. If mutation
appears to do nothing, check the feature gate before debugging the CEL. Managed control
planes that do not expose API-server flags cannot use the beta version at all.

#### Kyverno: allowlist the destination, not the source

If you run `kyvernoPolicies`, its `restrict-image-registries` policy permits only
`registry1.dso.mil` and `registry.dso.mil`. `MutatingAdmissionPolicy` is a *mutating*
plugin and therefore runs **before** Kyverno's *validating* webhook, so Kyverno inspects
the image **after** rewriting. You must allowlist the registry you rewrote **to**, even
though every manifest you authored names `registry1.dso.mil`:

```yaml
kyvernoPolicies:
  values:
    policies:
      restrict-image-registries:
        parameters:
          allow:
            - registry.example.mil
```

Without it, every pod is refused at admission:

```
admission webhook "validate.kyverno.svc-fail" denied the request:
restrict-image-registries: 'Image registry is not in the approved list.'
```

**This failure is delayed and easy to misread.** Pods admitted before Kyverno started
keep running, so a cluster that already looks healthy stays healthy until something
churns — the breakage surfaces on the next upgrade, node drain, or rollout, as workloads
that will not reschedule. If you enable Kyverno after rewriting is already in place,
apply this override in the same change.

### Images: a containerd registry mirror (alternative)

Where you control node configuration and would rather not run an admission policy, a
registry mirror achieves the same result at the pull layer. Image references stay
`registry1.dso.mil/...` and containerd redirects them. On k3s or RKE2,
`/etc/rancher/k3s/registries.yaml`:

```yaml
mirrors:
  "registry1.dso.mil":
    endpoint:
      - "https://registry.example.mil"

configs:
  "registry.example.mil":
    tls:
      ca_file: /etc/ssl/certs/your-ca.crt
```

This works because the mirror and hauler are two halves of one convention. Hauler strips
the source registry host on push and keeps the repository path; the mirror substitutes
the host back and appends that same path, so
`registry1.dso.mil/ironbank/big-bang/base:2.1.0` is served from
`registry.example.mil/ironbank/big-bang/base:2.1.0` — exactly where `hauler store copy`
put it.

Two consequences worth knowing. Because references are unchanged, Kyverno's
`restrict-image-registries` keeps working with its default allowlist and needs no
override. And because the redirect happens below Kubernetes entirely, it covers every
image regardless of how it was referenced, with nothing to apply in the right order.

The trade-off is reach: it requires node-level configuration on every node, which rules
it out on managed control planes and on Fargate.

### Charts: Big Bang values

Charts are fetched by Flux over HTTP, so neither admission rewriting nor a registry
mirror touches them -- both operate on pods. Point the Helm repository at
your registry and switch the packages onto it:

```yaml
helmRepositories:
  - name: "registry1"
    repository: "oci://registry.example.mil/bigbang"
    type: "oci"
    username: ""
    password: ""

istiod:
  sourceType: "helmRepo"
# ...and every other package you enable
```

Two things that will trip you up:

- **Every package defaults to `sourceType: "git"`.** Without flipping them the OCI charts
  in the archive go unused and you still need `repositories.tar.gz` plus a git server.
- **An unauthenticated registry is not directly expressible.** The values schema requires
  `existingSecret`, or `username` **and** `password`, or a non-generic `provider`. Empty
  strings satisfy the schema and stay falsy in the template, so no `secretRef` is
  rendered — that is the `username: ""` / `password: ""` above.

### TLS is required for the chart registry

Big Bang cannot emit `insecure` or `certSecretRef` on the `HelmRepository`, so a
plain-HTTP registry will not work for charts. The registry needs a real certificate, and
Flux's **source-controller needs the CA** — it runs as a pod, so the node trust store
does not reach it. Patch it in when you install Flux from `base/flux`:

```yaml
patches:
  - target:
      kind: Deployment
      name: source-controller
    patch: |-
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: source-controller
      spec:
        template:
          spec:
            containers:
            - name: manager
              env:
              - name: SSL_CERT_FILE
                value: /etc/ssl/certs/your-ca.crt
              volumeMounts:
              - name: registry-ca
                mountPath: /etc/ssl/certs/your-ca.crt
                subPath: ca.crt
                readOnly: true
            volumes:
            - name: registry-ca
              configMap:
                name: registry-ca
```

Mount it read-only; `base/flux` sets `readOnlyRootFilesystem: true`. Note `SSL_CERT_FILE`
replaces Go's trust store rather than adding to it, which is fine in a disconnected
environment. The symptom of getting this wrong is a `HelmRepository` stuck on an x509
error.

Flux's own controller images are in the archive at the versions `base/flux` pins, and the
mirror covers them, so no image changes are needed there.

### Harbor under a single project

Endpoint substitution appends the original path, so a mirror pointing at
`https://harbor.example.mil` yields `harbor.example.mil/ironbank/...` and needs an
`ironbank` project. If you require everything under one project instead
(`harbor.example.mil/bigbang/ironbank/...`), a plain endpoint will not do it — k3s
exposes a `rewrite` option taking regular expressions for that case.

### AWS: EKS and ECR

ECR needs preparation before the archive will push at all, and the choice of rewriting
mechanism is decided for you.

- **ECR does not create repositories on push.** Unless a repository creation template
  matches, the push fails. Before `hauler store copy`, either pre-create every repository
  or add a repository creation template with **Applied for: `CREATE_ON_PUSH`** and prefix
  `ROOT`. This is a one-time registry setting, and the archive contains roughly 190
  repositories.
- **A registry mirror is not available.** It needs node-level containerd configuration,
  which managed node groups allow only through launch template user data and Bottlerocket
  through settings — and Fargate not at all.
- **Use `MutatingAdmissionPolicy`.** On Kubernetes 1.36+ it is stable and on by default,
  so it needs no API-server flags and works on managed control planes. On 1.34-1.35 it is
  beta and requires flags EKS does not expose, so it is unavailable there.

Rewriting to ECR has a further advantage: the node's IAM role authenticates to ECR
natively, so no pull secret is required. Big Bang documents that case as
`registryCredentials: null`.

If you are on a Kubernetes version below 1.36 on EKS, neither a mirror nor an in-tree
policy is available, and the remaining option is a Kyverno mutating `ClusterPolicy`.
Note the bootstrap cost: Kyverno cannot mutate the pods that install Kyverno, so its own
images and the `kubectl` image in the `kyverno-policies` wait-job must be rewritten with
`postRenderers` first, and Flux's four controller images with a kustomize `images:`
transformer in your `base/flux` overlay.

### Verifying it actually came from your registry

```shell
kubectl get helmrepository -n bigbang    # should be Ready
kubectl get hr -A                        # HelmReleases reconciling
kubectl get po -A                        # no ImagePullBackOff
```

**If you rewrote at admission**, the pod specs are the evidence — they should name your
registry, not the one in the manifests you applied. This should return zero:

```shell
kubectl get po -A -o json \
  | jq '[.items[].spec | (.containers[]?, .initContainers[]?) | .image]
        | map(select(startswith("registry1.dso.mil"))) | length'
```

Check a pod in an istio-injected namespace specifically. The sidecar is added by a
separate webhook, so it is the case most likely to be missed — if `istio-proxy` still
names `registry1.dso.mil`, `reinvocationPolicy: IfNeeded` is not set.

**If you used a mirror**, pod specs still say `registry1.dso.mil` by design, so a running
pod proves nothing on its own. The registry's access log is the only evidence: if a pod
is Running and your registry logged nothing for that image, it reached upstream and the
mirror is not doing its job.

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
