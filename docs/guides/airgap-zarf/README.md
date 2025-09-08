# Airgap with Zarf

### Requires Big Bang 3.1 or greater.

## What is Zarf?

>Zarf is a free and open source tool that enables declarative creation & distribution of software into air-gapped/constrained/standalone environments.

>Zarf provides a way to package and deploy software in a way that is repeatable, secure, and reliable.

The complete documentation for zarf is [here](https://docs.zarf.dev/)

There main use case is to usr zarf to combine all of your packages needed for transport across an airgap and use the 'zarf' file to deploy those packages into your airgap'ed environment.

## Prerequisites

To use Zarf with BigBang you need to first do the following steps:
1. Use the k3d-dev.sh script to establish an EC2 instance with all necessary components, especially k3d networking.
```shell
docs/assets/scripts/developer/k3d-dev.sh -b
```
2. Export the Registry1 credentials you want to use in the process.  These credentials will be used when accessing component images from registry1.dso.mil.
```shell
export REGISTRY1_USERNAME=<username>
export REGISTRY1_PASSWORD=<password>
```

3. Install zarf.  The documentation for the steps to install are [here](https://docs.zarf.dev/getting-started/install/). 
Basically, 
- find the latest version of zarf, 
- download to your machine, 
- mv it to your EC2 bin directory, and 
- chmod +x to make it executable.

## Some Overall Usage Guidelines

### Shut off logging when passing credentials 

In this example we are logging into the zarf tools registry.  We need to pass in the password, but we don't want it to show in the logs.  We
- `set +o history` - disable command history
- `echo ${REGISTRY1_PASSWORD}` - to provide the password to standard input
- run the command with additional parameter `--password-stdin` so that zarf looks to stdin for the password rather than the command line argument
- `set -o history` - turn command history back on
```aiignore
set +o history && echo ${REGISTRY1_PASSWORD} | zarf tools registry login registry1.dso.mil --username ${REGISTRY1_USERNAME} --password-stdin --log-level=${ZARF_LOG_LEVEL} || set -o history
```

### Use zarf logging
```aiignore
ZARF_LOG_LEVEL=${ZARF_LOG_LEVEL:=debug}
...
zarf <command> --log-level=${ZARF_LOG_LEVEL}
```
Where the log levels are:
- warn: Displays only warning and error messages.
- info: (Default) Displays informational messages, warnings, and errors.
- debug: Displays detailed debugging information, in addition to info, warn, and error messages.
- trace: Provides the most verbose output, including highly granular tracing information.

## Steps to create a zarf file and deploy to your k3d cluster

These steps are detailed in the online zarf documentation [here](https://docs.zarf.dev/tutorials/0-creating-a-zarf-package/).  The following are the high points you need to cover.

### 1. Ensure prerequisites are available

Your solution should make sure these are available:
- Docker
- Kubernetes
- Any additional requirements for your implementation

In your final script you may want to determine if the cluster has already been created and running.

### 2. Initialize Zarf

We initialize zarf to set to use the k3d cluster.  The parameters passed are:
- `--components=git-server` - to install a git server in the cluster for use by zarf
- `--confirm` - to automatically reply affirmative to the several queries presented during init, e.g. Do you want to install?

```aiignore
zarf init --components=git-server --confirm
```

### 3. Login to Docker

Zarf will be using Docker (running in your k3d cluster) to store the images pulled from repo1.  This step allows everything to proceed.

We are using the same method as above to avoid logging credentials.

```aiignore
set +o history && echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin "$DOCKER_REGISTRY" || set -o history
```

### 4. Create our package

Now that all the preliminaries are complete we can create a package.

```aiignore
zarf package create . --confirm --log-level=${ZARF_LOG_LEVEL}
```

This command assumes that the `zarf.yaml` file is local.  See the appendix below for details on the zarf.yaml file.

The package file will be named zarf-package-bigbang-amd64.tar.zst:
- `zarf-package` is fixed
- `bigbang` is determined from the yaml file.
- `amd64` is the targeted EC2 instance CPU type

### 5. Inspect (Optional)

This step displays the definition of a Zarf package.

```aiignore
zarf package inspect definition zarf-package-bigbang-amd64.tar.zst
```

### 6. Deploy

Deploys a Zarf package from the local file Unpacks resources and dependencies from a Zarf package archive and deploys them onto the target system. 

Kubernetes clusters are accessed via credentials in your current kubecontext defined in ’~/.kube/config’

Kubernetes would have been installed with the earlier k3d-dev.sh step.

```aiignore
zarf package inspect definition zarf-package-bigbang-amd64.tar.zst
```

### 7. Cleanup

If this was a test run then the whole EC2 instance will be destroyed within hours so no cleanup is necessary.

# Appendix A - zarf.yaml file

The zarf.yaml file contains the list of applications to be extracted from repo1 and stored into the package file (zarf-package-bigbang-amd64.tar.zst).

Below is a sample zarf.yaml (updated to correspond to applications in use in August 2025)

Some notes:
- `apiVersion` is fixed to the current version of zarf at this time
- `kind` is fixed per zarf
- `metadata\name` is provided by us (and also used in the generated zarf file)
- `architecture` is provided by us (and also used in the generated zarf file)
- `manifests\files` provides the overall driving application controlling the others.  Currently, this is kyverno.
- `images` is the list of OCI (Open Container Initiative) compliant container images to include.
- `repos` is the list of Git repositories, which typically contain source code, Helm charts, Kubernetes manifests, or other configuration files.  These provide the necessary code and configuration to deploy and manage applications within the air-gapped environment.
- `actions` provides a list of actions to perform during key stages of its lifecycle.  The stages available are:
  - onCreate - Runs during zarf package create. 
  - onDeploy - Runs during zarf package deploy. 
  - onRemove - Runs during zarf package remove.
- `healthchecks` - provide entry points for zarf to determine the health of components

```aiignore
apiVersion: zarf.dev/v1alpha1
kind: ZarfPackageConfig
metadata:
  name: bigbang
  architecture: amd64
components:
  - name: bigbang
    required: true
    manifests:
      - name: bigbang
        namespace: bigbang
        files:
          - config/kyverno.yaml #exists
    images:
      - registry1.dso.mil/ironbank/big-bang/base:2.1.0
      - registry1.dso.mil/ironbank/big-bang/grafana/grafana-plugins:12.1.0
      - registry1.dso.mil/ironbank/kiwigrid/k8s-sidecar:1.30.9
      - registry1.dso.mil/ironbank/neuvector/neuvector/controller:5.4.5
      - registry1.dso.mil/ironbank/neuvector/neuvector/enforcer:5.4.5
      - registry1.dso.mil/ironbank/neuvector/neuvector/manager:5.4.5
      - registry1.dso.mil/ironbank/neuvector/neuvector/prometheus-exporter:1-1.0.0
      - registry1.dso.mil/ironbank/neuvector/neuvector/scanner:6
      - registry1.dso.mil/ironbank/opensource/grafana/loki:3.5.3
      - registry1.dso.mil/ironbank/opensource/grafana/promtail:v3.5.3
      - registry1.dso.mil/ironbank/opensource/grafana/tempo-query:2.8.2
      - registry1.dso.mil/ironbank/opensource/grafana/tempo:2.8.2
      - registry1.dso.mil/ironbank/opensource/ingress-nginx/kube-webhook-certgen:v1.6.1
      - registry1.dso.mil/ironbank/opensource/istio/operator:1.23.6
      - registry1.dso.mil/ironbank/tetrate/istio/pilot:1.25.2
      - registry1.dso.mil/ironbank/tetrate/istio/proxyv2:1.26
      - registry1.dso.mil/ironbank/opensource/kiali/kiali-operator:v2.14.0
      - registry1.dso.mil/ironbank/opensource/kiali/kiali:v2.14.0
      - registry1.dso.mil/ironbank/opensource/kubernetes-sigs/metrics-server:v0.8.0
      - registry1.dso.mil/ironbank/opensource/kubernetes/kube-state-metrics:v2.16.0
      - registry1.dso.mil/ironbank/opensource/kubernetes/kubectl:v1.32
      - registry1.dso.mil/ironbank/opensource/kyverno:v1.12.5
      - registry1.dso.mil/ironbank/opensource/kyverno/kyverno/background-controller:v1.12.5
      - registry1.dso.mil/ironbank/opensource/kyverno/kyverno/cleanup-controller:v1.12.5
      - registry1.dso.mil/ironbank/opensource/kyverno/kyverno/reports-controller:v1.12.5
      - registry1.dso.mil/ironbank/opensource/kyverno/kyvernocli:v1.12.5
      - registry1.dso.mil/ironbank/opensource/kyverno/kyvernopre:v1.12.5
      - registry1.dso.mil/ironbank/opensource/kyverno/policy-reporter:3.4.1
      - registry1.dso.mil/ironbank/opensource/kyverno/policy-reporter/kyverno-plugin:0.5.0
      - registry1.dso.mil/ironbank/opensource/prometheus-operator/prometheus-config-reloader:v0.85.0
      - registry1.dso.mil/ironbank/opensource/prometheus-operator/prometheus-operator:v0.85.0
      - registry1.dso.mil/ironbank/opensource/prometheus/alertmanager:v0.28.1
      - registry1.dso.mil/ironbank/opensource/prometheus/node-exporter:v1.9.1
      - registry1.dso.mil/ironbank/opensource/prometheus/prometheus:v3.5.0
      - registry1.dso.mil/ironbank/opensource/thanos/thanos:v0.39.2
      - registry1.dso.mil/ironbank/redhat/ubi/ubi9-minimal:9.6
    repos:
      - https://repo1.dso.mil/big-bang/bigbang@3.5.0
      - https://repo1.dso.mil/big-bang/product/packages/grafana.git@9.3.1-bb.1
      - https://repo1.dso.mil/big-bang/product/packages/istio-gateway.git@1.27.0-bb.0
      - https://repo1.dso.mil/big-bang/product/packages/istio-operator.git@1.23.6-bb.0
      - https://repo1.dso.mil/big-bang/product/packages/kiali.git@2.14.0-bb.0
      - https://repo1.dso.mil/big-bang/product/packages/kyverno-policies.git@3.3.4-bb.11
      - https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter.git@3.3.2-bb.3
      - https://repo1.dso.mil/big-bang/product/packages/kyverno.git@3.4.4-bb.3
      - https://repo1.dso.mil/big-bang/product/packages/loki.git@6.30.1-bb.4
      - https://repo1.dso.mil/big-bang/product/packages/metrics-server.git@3.12.2-bb.5
      - https://repo1.dso.mil/big-bang/product/packages/monitoring.git@75.6.1-bb.3
      - https://repo1.dso.mil/big-bang/product/packages/neuvector.git@2.8.7-bb.0
      - https://repo1.dso.mil/big-bang/product/packages/tempo.git@1.21.1-bb.2
    actions:
      onRemove:
        before:
          - cmd: ./zarf tools kubectl patch helmrelease -n bigbang bigbang --type=merge -p '{"spec":{"suspend":true}}'
            description: Suspend Big Bang HelmReleases to prevent reconciliation during removal.
    healthChecks:
      - apiVersion: helm.toolkit.fluxcd.io/v2
        kind: HelmRelease
        namespace: bigbang
        name: grafana #exists
      - apiVersion: helm.toolkit.fluxcd.io/v2
        kind: HelmRelease
        namespace: bigbang
        name: istio
      - apiVersion: helm.toolkit.fluxcd.io/v2
        kind: HelmRelease
        namespace: bigbang
        name: istio-operator
      - apiVersion: helm.toolkit.fluxcd.io/v2
        kind: HelmRelease
        namespace: bigbang
        name: kiali
      - apiVersion: helm.toolkit.fluxcd.io/v2
        kind: HelmRelease
        namespace: bigbang
        name: kyverno
      - apiVersion: helm.toolkit.fluxcd.io/v2
        kind: HelmRelease
        namespace: bigbang
        name: kyverno-policies
      - apiVersion: helm.toolkit.fluxcd.io/v2
        kind: HelmRelease
        namespace: bigbang
        name: kyverno-reporter
      - apiVersion: helm.toolkit.fluxcd.io/v2
        kind: HelmRelease
        namespace: bigbang
        name: loki
      - apiVersion: helm.toolkit.fluxcd.io/v2
        kind: HelmRelease
        namespace: bigbang
        name: monitoring
      - apiVersion: helm.toolkit.fluxcd.io/v2
        kind: HelmRelease
        namespace: bigbang
        name: neuvector
      - apiVersion: helm.toolkit.fluxcd.io/v2
        kind: HelmRelease
        namespace: bigbang
        name: promtail
      - apiVersion: helm.toolkit.fluxcd.io/v2
        kind: HelmRelease
        namespace: bigbang
        name: tempo

```