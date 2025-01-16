# Post-Renderers in Helm, Flux, and Kustomize

Post-renderers are a powerful feature that extend the functionality of Helm by enabling custom modifications to rendered Kubernetes manifests before they are applied to the cluster. This doc explores post-renderers: their applications, advantages, and limitations, particularly in the context of Helm, Flux, and Kustomize.

---

## What Are Post-Renderers?

A **post-renderer** is a program or script that Helm executes _after_ rendering a chart but _before_ applying the resulting Kubernetes manifests to a cluster. Post-renderers allow you to:

- Make adjustments to Kubernetes manifests without having to fork from the upstream repository.
- Apply organization-specific policies or transformations.
- Integrate external tools to enhance the generated manifests.

For more details, see the [Helm documentation on post-renderers](https://helm.sh/docs/topics/advanced/#post-rendering).

---

## Advantages of Using Post-Renderers

Using post-renderers in a repository offers several advantages, the biggest of which at Big Bang is allowing for security-hardened modifications without having to fork upstream charts:

1. **Customizability:**
   - Post-renderers allow you to tailor Kubernetes manifests to specific organizational requirements without altering the upstream Helm chart or templates.

2. **Policy Enforcement:**
   - Security and compliance policies can be enforced dynamically by injecting labels, annotations, or security contexts into resources.

3. **Reuse of Charts:**
   - By using post-renderers, the same Helm chart can be reused across multiple environments with unique configurations applied during deployment.

4. **Seamless Integration:**
   - Post-renderers can integrate external tools or scripts into the deployment pipeline, making it easier to manage complex workflows.

5. **Environment-Specific Customization:**
   - Tailor deployments to different environments (e.g., development, staging, production) by dynamically altering configurations.

---

## How Post-Renderers Work in Helm

1. **Execution Flow:**
   - Helm renders the chart templates.
   - The rendered output is passed to the post-renderer.
   - The post-renderer modifies the manifests as needed and returns the updated output.

---

## Post-Renderers in Flux

At Big Bang we apply post-renders through Flux, a GitOps tool that integrates with Helm charts via the Helm Controller using the `HelmRelease` resource's built-in Kustomize directives.

**HelmRelease Resource:**
   In Flux, the `HelmRelease` resource is used to deploy Helm charts. To apply Kustomize post-rendering you can use HelmRelease `spec.postRenderers` (see [Helm Release postRenderers](https://fluxcd.io/flux/components/helm/helmreleases/#post-renderers) for more info) to modify Kubernetes resources that are deployed from that HelmRelease:
   - Preprocess the manifests using Kustomize before defining them in the `HelmRelease`.
   - Use pre-built automation pipelines in your CI/CD system to simulate post-renderer logic.

## Post-Rendering Example in Big Bang
An example of using post-renderers in Big Bang can be found in the Mimir template. 

1. The Mimir template in the Big Bang umbrella chart contains a `_postrenderers.tpl` file: [bigbang/chart/templates/mimir/_postrenderers.tpl](https://repo1.dso.mil/big-bang/bigbang/-/blob/epic-414/mimir-sandbox/chart/templates/mimir/_postrenderers.tpl?ref_type=heads) (this specific template adds tcp/grpc appProtocols to the Mimir service, a new containerPort, and an `app.kubernetes.io~1part-of` label to the Mimir query-frontend deployment).
2. The HelmRelease resource for Mimir includes the `mimir.istioPostRenderers` from the `_postrenderers.tpl` template (found under `spec.postRenderers`): [bigbang/chart/templates/mimir/helmrelease.yaml](https://repo1.dso.mil/big-bang/bigbang/-/blob/epic-414/mimir-sandbox/chart/templates/mimir/helmrelease.yaml?ref_type=heads#L42).
3. Post-renderers get applied during the `helm install`, patching the Mimir service/deployments.

---

## Limitations of Post-Renderers

### Helm:
- **Does not support Helm tests:** Post-renderers are not executed during `helm test` runs. This can lead to discrepancies between the test and actual deployments.

---

## Conclusion

Post-renderers provide flexibility for last-minute customizations of Kubernetes manifests. However, their integration with tools like Flux and Kustomize introduces additional complexity. Understanding their advantages and limitations ensures smoother deployments and maintainable workflows.

For more information, refer to:
- [Helm Post-Rendering](https://helm.sh/docs/topics/advanced/#post-rendering)
- [Flux Helm Release Post Renderers](https://fluxcd.io/flux/components/helm/helmreleases/#post-renderers)
- [Kustomize Documentation](https://kustomize.io/)
