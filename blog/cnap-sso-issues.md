---
revision_date: Last edited December 19th, 2024
tags:
  - blog
  - sso
  - cnap
---

# Big Bang SSO Error RCA & Resolution

The big bang engineering team recently encountered a break in the SSO functionality
for our dogfood cluster as well as our developer environments under certain
configurations. In this post, we'd like to share our root-cause analysis and go
over solutions for big bang consumers that may encounter similar issues.

## Background

Beginning Thursday Dec 12th 2024, Big Bang release engineers noticed an issue
with SSO logins to various
[`authservice`](https://github.com/istio-ecosystem/authservice)-backed big-bang
services: [`alertmanager`](https://github.com/prometheus/alertmanager),
[`prometheus`](https://github.com/prometheus/prometheus), and
[`tempo`](https://github.com/grafana/tempo)/[`jaeger`](https://github.com/jaegertracing/jaeger)
to name a few.

Upon visiting any of the affected services, the users would be redirected to
CNAP's hosted [keycloak login portal](https://login.dso.mil) where they would
complete authentication and be redirected back to their application. Upon
returning to the application, they would not be permitted into the application
and would instead receive a `403` error with the error message:
`Jwt authentication fails`

## Root Cause

### (Not) Entrust Root CA

Originally, several Big Bang team members believed the issue was related to
`login.dso.mil` using a cert signed by a
[no longer trusted](https://security.googleblog.com/2024/06/sustaining-digital-certificate-security.html)
root CA. This is not the case.

### SSL.com Root CA

On or after December 3rd 2024, `login.dso.mil` was updated to use a new TLS
certificate signed by Entrust OV TLS Issuing RSA CA 1. This certificate is
signed by SSL.com TLS RSA Root CA 2022, a relatively young CA, with a
certificate that is trusted by browser vendors but is not yet propagated to all
Linux releases.

### Outdated Cert Bundle in Distroless

Many of the containers in use by big bang are based on the upstream
[distroless](https://github.com/GoogleContainerTools/distroless) images put out
by Google. A
[longstanding issue](https://github.com/GoogleContainerTools/distroless/issues/753)
on that project outlines the situation well: distroless copies the CA bundle
from `debian:bookworm` wholesale without updating the cert bundle to the latest
offered by Mozilla Network Security Services (nss). Unfortunately this means
that the root CA that signed `login.dso.mil`'s TLS certificate was not trusted
by any of the big bang containers.

### "Jwt authentication fails"

The error received was worded in such a way that it was possible to trace
exactly where it was coming from. It's a
[`Status`](https://github.com/google/jwt_verify_lib/blob/b59e8075d4a4f975ba6f109e1916d6e60aeb5613/src/status.cc#L78)
type from Google's
[JWT Verify Library](https://github.com/google/jwt_verify_lib) for C++, a
library
[used by Envoy](https://github.com/envoyproxy/envoy/blob/b87da3fa9f008d87ab02df53840c5246f1ba6209/source/extensions/filters/http/jwt_authn/authenticator.cc#L17)
to validate [JWT](https://datatracker.ietf.org/doc/html/rfc7519)s when it's
configured with
[JwtAuthentication](https://github.com/envoyproxy/envoy/blob/70b74781ad29f61fc5e378d792ad62adbef86dea/api/envoy/extensions/filters/http/jwt_authn/v3/config.proto#L734).
Envoy is the proxy Istio uses to facilitate much of its functionality and
`istiod` is the component of Istio that discovers configuration in the
environment and translates that into effective configurations for Envoy.

### `istiod`

SSO is configured within Big Bang via a
[`RequestAuthentication`](https://istio.io/latest/docs/reference/config/security/request_authentication/)
CRD. This CRD configures (among other things) the
[JWKS](https://datatracker.ietf.org/doc/html/rfc7517#appendix-A) endpoint where Istio can
find the public keys used to sign JWTs. After it fetches the JWKS, it configures
envoy by creating a `JwtAuthentication` and pushing it out to the envoy proxy
containers. Unfortunately, since `istiod` is based on `distroless`, the cert
bundle baked into the image does not trust `login.dso.mil` and this process
fails with logs similar to below present in `istiod`:

```
2024-12-17T18:03:30.696537Z     warn    model   Failed to GET from "https://login.dso.mil/auth/realms/baby-yoda/protocol/openid-connect/certs": Get "https://login.dso.mil/auth/realms/baby-yoda/protocol/openid-connect/certs": tls: failed to verify certificate: x509: certificate signed by unknown authority. Retry in 1s
```

As a result of this, the envoy proxies that are responsible for authenticating
SSO-enabled applications without their own built-in SSO support are unable to
verify the JWTs returned from CNAP's keycloak instance, leading to the error the
Big Bang engineers encountered.

## Resolution

### Manual Trust

Big Bang exposes the ability to set trusted CAs for the JWKS fetch via
`sso.certificateAuthority.cert`. By setting this to `login.dso.mil`'s cert
bundle, the endpoint will be trusted explicitly and the JWKS fetch will succeed.

### Upgrades

Unfortunately, `istiod` does not pick up changes to this cert bundle during
runtime. If upgrading from a previous release with different certificates or no
certificates at all, it's important to restart the `istiod` deployment so that
it can pick up the changes:

```sh
kubectl -n istio-system rollout restart deployment/istiod
```

This last step was unfortunately the missing ingredient for our dogfood cluster.
Big Bang engineers had already configured the SSO trust chain to include these
certificates, but without this final piece, the cluster would not recover.
Thankfully, having delved into the root cause, we could confirm our resolution
and restore our dogfood cluster to working order.
