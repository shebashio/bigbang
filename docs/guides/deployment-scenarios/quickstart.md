# Quick Start

[[_TOC_]]

## Big Bang in 1 hour

An SRE with a reasonable amount of experience operating in a command line environment, equipped with a decent internet connection and a workstation they can install software on, should be able to complete this process and have an operational Big Bang dev environment in 1 hour or less.

### Satisfy the Prerequisites

1. Ensure your workstation has a functional GNU environment with `git`. Mac OS and Linux should be good to go out of the box. For Windows, the **only** supported method for this guide is to install WSL and run a WSL bash terminal, following the rest of the guide as a Linux user inside WSL.
1. Install [jq](https://jqlang.github.io/jq/download/).
1. Install [yq](https://github.com/mikefarah/yq/#install). yq needs to be available in your system path PATH as `yq`, so we recommend not using a dockerized installation.
1. Install kubectl. Follow the instructions for [windows](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/), [macos](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/) or [linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/). (If you are running on WSL in Windows, you should install kubectl using the package manager inside of WSL to install kubectl.)
1. [Install helm](https://helm.sh/docs/intro/install/).
1. [Install the Flux CLI](https://fluxcd.io/flux/installation/).
1. Ensure you have bash version 4 installed. Linux and Windows with WSL users probably don't need to worry about this. For Mac OS users, install bash4 with homebrew or a similar package manager, as the bash that ships with Mac OS is hopelessly old. Mac OS users will use `/opt/homebrew/bin/bash` whenever `bash` is mentioned in this guide.
1. Ensure you have an account on [PlatformOne RegistryOne](https://registry1.dso.mil). You will need your username and access token ("CLI Secret") for this process.

### Build the Cluster

Run the following commands in your terminal to download the quickstart script, which you will use in the next step:

```
export REGISTRY1_USERNAME=YOUR_REGISTRY1_USERNAME
export REGISTRY1_TOKEN=YOUR_REGISTRY1_TOKEN
export REPO1_LOCATION=LOCATION_ON_FILESYSTEM_TO_CHECK_OUT_BIGBANG_CODE

curl --output quickstart.sh https://repo1.dso.mil/big-bang/bigbang/-/raw/master/docs/assets/scripts/quickstart.sh?ref_type=heads
```

#### Using a VM or other hardware you built yourself

1. Spin up an Ubuntu VM somewhere with 8 CPUs and 32gB of RAM. Make sure you can SSH to it. It doesn't matter what cloud provider you're using, it can even be on your local system if you have enough horsepower for it. 
1. Run the following command in your command terminal:

```
bash quickstart.sh
  -H YOUR_VM_IP \
  -U YOUR_VM_SSH_USERNAME \
  -K YOUR_VM_SSH_KEY_FILE_PATH
```

#### Using Amazon Web Services

1. If your system is already configured to use AWS via the `aws-cli` and you don't want to go to the trouble of building your own VM, the quickstart can attempt to do it for you; simply run the quickstart with no arguments. Pay attention to the script output; the IP addresses of the created AWS EC2 instance will be printed after the cluster is built and before big bang is deployed. You may need these later.
1. Run the following commands in your command terminal:

```
bash quickstart.sh
```

### It's thinking

Go make a sandwich, the process takes about 10 minutes. Once the command finishes, you will still need to wait a while longer before the cluster is actually ready to use.

### What Just Happened? In Detail

The quickstart.sh script performs several actions:

1. Checks your system to make sure the prerequisites we talked about are present
1. If you're an AWS Cloud user who didn't provide `-H`, `-K`, and `-U` settings, attempts to build an EC2 instance suitable for use as a Big Bang cluster inside the default VPC in your configured AWS account and region
1. Connects to your system over SSH to perform several configuration steps, including:
1.1 Enabling passwordless sudo
1.1 Ensuring your system packages are up to date
1.1 Installing k3d/k3s
1.1 Configuring a single-node Kubernetes cluster on your VM using k3d
1. Installs the flux kubernetes extensions on your k3d cluster
1. Checks out the PlatformOne Big Bang repository to the location specified when you ran the command
1. Installs the Big Bang umbrella chart into your k3d cluster
1. Waits for Big Bang to completely deploy, which may take a significant amount of time

### Hurry Up And Wait

The final step of the process, waiting for big bang to fully deploy, can take a significant amount of time. You can inspect the state of the system in another terminal while this is occurring if you desire.

Run `kubectl get po -A` in your terminal (which is the shorthand of `kubectl get pods --all-namespaces`). If you see something like the following, stating that some pods are not ready, then you will need to wait longer.

  ```console
  NAMESPACE           NAME                                                READY   STATUS          RESTARTS   AGE
  kube-system         metrics-server-86cbb8457f-dqsl5                     1/1     Running             0      39m
  kube-system         coredns-7448499f4d-ct895                            1/1     Running             0      39m
  flux-system         notification-controller-65dffcb7-qpgj5              1/1     Running             0      32m
  flux-system         kustomize-controller-d689c6688-6dd5n                1/1     Running             0      32m
  flux-system         source-controller-5fdb69cc66-s9pvw                  1/1     Running             0      32m
  kube-system         local-path-provisioner-5ff76fc89d-gnvp4             1/1     Running             1      39m
  flux-system         helm-controller-6c67b58f78-6dzqw                    1/1     Running             0      32m
  gatekeeper-system   gatekeeper-controller-manager-5cf7696bcf-xclc4      0/1     Running             0      4m6s
  gatekeeper-system   gatekeeper-audit-79695c56b8-qgfbl                   0/1     Running             0      4m6s
  istio-operator      istio-operator-5f6cfb6d5b-hx7bs                     1/1     Running             0      4m8s
  eck-operator        elastic-operator-0                                  1/1     Running             1      4m10s
  istio-system        istiod-65798dff85-9rx4z                             1/1     Running             0      87s
  istio-system        public-ingressgateway-6cc4dbcd65-fp9hv              0/1     ContainerCreating   0      46s
  logging             logging-fluent-bit-dbkxx                            0/2     Init:0/1            0      44s
  monitoring          monitoring-monitoring-kube-admission-create-q5j2x   0/1     ContainerCreating   0      42s
  logging             logging-ek-kb-564d7779d5-qjdxp                      0/2     Init:0/2            0      41s
  logging             logging-ek-es-data-0                                0/2     Init:0/2            0      44s
  istio-system        svclb-public-ingressgateway-ggkvx                   5/5     Running             0      39s
  logging             logging-ek-es-master-0                              0/2     Init:0/2            0      37s
  ```

Wait up to 10 minutes then re-run `kubectl get po -A`, until all pods show STATUS Running. Once all the pods show running, run `helm list -n=bigbang` in your terminal. All helm releases should show STATUS deployed

  ```console
  NAME                           	NAMESPACE        	REVISION	UPDATED                                	STATUS  	CHART                            	APP VERSION
  bigbang                        	bigbang          	1       	2022-03-31 12:07:49.239343968 +0000 UTC	deployed	bigbang-1.30.1
  cluster-auditor-cluster-auditor	cluster-auditor  	1       	2022-03-31 12:14:23.004377605 +0000 UTC	deployed	cluster-auditor-1.4.0-bb.0       	0.0.4
  eck-operator-eck-operator      	eck-operator     	1       	2022-03-31 12:09:52.921098159 +0000 UTC	deployed	eck-operator-2.0.0-bb.0          	2.0.0
  gatekeeper-system-gatekeeper   	gatekeeper-system	1       	2022-03-31 12:07:53.52890717 +0000 UTC 	deployed	gatekeeper-3.7.1-bb.0            	v3.7.1
  istio-operator-istio-operator  	istio-operator   	1       	2022-03-31 12:07:55.111321595 +0000 UTC	deployed	istio-operator-1.13.2-bb.1       	1.13.2
  istio-system-istio             	istio-system     	1       	2022-03-31 12:08:23.439981427 +0000 UTC	deployed	istio-1.13.2-bb.0                	1.13.2
  jaeger-jaeger                  	jaeger           	1       	2022-03-31 12:12:58.068313509 +0000 UTC	deployed	jaeger-operator-2.29.0-bb.0      	1.32.0
  kiali-kiali                    	kiali            	1       	2022-03-31 12:12:57.011215896 +0000 UTC	deployed	kiali-operator-1.47.0-bb.1       	1.47.0
  logging-ek                     	logging          	1       	2022-03-31 12:10:52.785810021 +0000 UTC	deployed	logging-0.7.0-bb.0               	7.17.1
  logging-fluent-bit             	logging          	1       	2022-03-31 12:12:53.27612266 +0000 UTC 	deployed	fluent-bit-0.19.20-bb.1          	1.8.13
  monitoring-monitoring          	monitoring       	1       	2022-03-31 12:10:02.31254196 +0000 UTC 	deployed	kube-prometheus-stack-33.2.0-bb.0	0.54.1
  ```

If any helm releases show STATUS other than `deployed` you will need to wait longer.

### Fix DNS to access the services in your browser

#### Linux/Mac Users

Run this command in your terminal:

```shell
echo YOUR_VM_IP       $(kubectl get virtualservices -A -o json | jq -r .items[].spec.hosts[0] | tr "\n" "\t") | sudo tee -a /etc/hosts
```

#### Windows Users

Run this command in your bash terminal, and copy the output to your clipboard.

```shell
echo YOUR_VM_IP       $(kubectl get virtualservices -A -o json | jq -r .items[].spec.hosts[0] | tr "\n" "\t")
```

1. Right click Notepad -> Run as Administrator
1. Open C:\Windows\System32\drivers\etc\hosts
1. Add the line from your clipboard to the bottom of the file
1. Save and close

### Access a BigBang Service

In a browser, visit one of the sites that you just added to your hosts file.

Note, default credentials for Big Bang packages can be found [here](../using-bigbang/default-credentials.md).

### Tinker With It

Here's an example of post deployment customization of Big Bang.  
After looking at <https://repo1.dso.mil/big-bang/bigbang/-/blob/master/chart/values.yaml>  
It should make sense that the following is a valid edit.

```shell
# [ubuntu@Ubuntu_VM:~]

cat << EOF > ~/tinkering.yaml
addons:
  argocd:
    enabled: true
EOF

source ~/lib/bigbang.sh

bb_k3d_deploy -f $HOME/demo_values.yaml -f $HOME/tinkering.yaml

# NOTE: There may be a ~1 minute delay for the change to apply

kubectl get vs -A
# Now ArgoCD should show up, if it doesn't wait a minute and rerun the command

kubectl get po -n=argocd
# Once these are all Running you can visit argocd's webpage
```

> Remember to un-edit your Hosts file when you are finished tinkering.

### Implementing Mission Applications within your bigbang environment

Big Bang by itself serves as a jumping off point, but many users will want to implement their own mission specific applications in to the cluster. BigBang has implemented a `packages:` and `wrapper:`  section to enable and support this in a way that ensures connectivity between your mission specific requirements and existing BigBang utilities, such as istio, the monitoring stack, and network policy management. [Here](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/guides/deployment-scenarios/extra-package-deployment.md) is the documentation for the `packages` utility.

We will implement a simple additional utility as a proof of concept, starting with a basic podinfo client. This will use the `wrapper` key to provide integration between bigbang and the Mission Application, without requiring the full Istio configuration to be placed inside BigBang specific keys of the dependent chart.


```shell
cat << EOF > ~/podinfo_wrapper.yaml
packages:
  # -- Package name.  Each package will be independently wrapped for Big Bang integration.
  # @default -- Uses `defaults/<package name>.yaml` for defaults.  See `package` Helm chart for additional values that can be set.
  podinfo:
    # -- Toggle deployment of this package
    # @default -- true
    enabled: true

    # -- Toggle wrapper functionality. See https://docs-bigbang.dso.mil/latest/docs/guides/deployment-scenarios/extra-package-deployment/#Wrapper-Deployment for more details.
    # @default -- false
    wrapper:
      enabled: true

    # -- Use a kustomize deployment rather than Helm
    kustomize: false

    # -- HelmRepo source is supported as an option for Helm deployments. If both `git` and `helmRepo` are provided `git` will take precedence.
    helmRepo:
      # -- Name of the HelmRepo specified in `helmRepositories`
      # @default -- Uses `registry1` Helm Repository if not specified
      repoName:
      # -- Name of the chart stored in the Helm repository
      # @default -- Uses values key/package name if not specified
      chartName:
      # -- Tag of the chart in the Helm repo, required
      tag:

    # -- Git source is supported for both Helm and Kustomize deployments. If both `git` and `helmRepo` are provided `git` will take precedence.
    git:
      # -- Git repo URL holding the helm chart for this package, required if using git
      repo: "https://repo1.dso.mil/big-bang/product/packages/podinfo.git"
      # -- Git commit to check out.  Takes precedence over semver, tag, and branch. [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference)
      commit:
      # -- Git semVer tag expression to check out.  Takes precedence over tag. [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference)
      semver:
      # -- Git tag to check out.  Takes precedence over branch. [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference)
      tag: "6.0.0-bb.7"
      # -- Git branch to check out.  [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference).
      # @default -- When no other reference is specified, `master` branch is used
      branch:
      # -- Path inside of the git repo to find the helm chart or kustomize
      # @default -- For Helm charts `chart`.  For Kustomize `/`.
      path: "chart"

    # -- Override flux settings for this package
    flux: {}

    # -- After deployment, patch resources.  [More info](https://fluxcd.io/flux/components/helm/helmreleases/#post-renderers)
    postRenderers: []

    # -- Specify dependencies for the package. Only used for HelmRelease, does not effect Kustomization. See [here](https://fluxcd.io/flux/components/helm/helmreleases/#helmrelease-dependencies) for a reference.
    dependsOn: []

    # -- Package details for Istio.  See [wrapper values](https://repo1.dso.mil/big-bang/apps/wrapper/-/blob/main/chart/values.yaml) for settings.
    istio:
      hosts:
        - names:
            - missionapp
          gateways:
            - public
          destination:
            service: missionapp-missionapp
            port: 9898

    # -- Package details for monitoring.  See [wrapper values](https://repo1.dso.mil/big-bang/apps/wrapper/-/blob/main/chart/values.yaml) for settings.
    monitor: {}

    # -- Package details for network policies.  See [wrapper values](https://repo1.dso.mil/big-bang/apps/wrapper/-/blob/main/chart/values.yaml) for settings.
    network: {}

    # -- Secrets that should be created prior to package installation.  See [wrapper values](https://repo1.dso.mil/big-bang/apps/wrapper/-/blob/main/chart/values.yaml) for settings.
    secrets: {}

    # -- ConfigMaps that should be created prior to package installation.  See [wrapper values](https://repo1.dso.mil/big-bang/apps/wrapper/-/blob/main/chart/values.yaml) for settings.
    configMaps: {}

    # -- Values to pass through to package Helm chart
    values: 
      istio:
        enabled: "{{ .Values.istio.enabled }}"
      ui:
        color: "#fcba03" #yellow

EOF

source ~/lib/bigbang.sh

bb_k3d_deploy -f $HOME/demo_values.yaml -f $HOME/podinfo_wrapper.yaml

# NOTE: There may be a ~1 minute delay for the change to apply

kubectl get vs -A
# Now missionapp should show up, if it doesn't wait a minute and rerun the command

kubectl get po -n=missionapp
# Once these are all Running you can visit missionapp's webpage
```

Wrappers also allow you to abstract out Monitoring, Secrets, Network Policies, and ConfigMaps. Additional Configuration information can be found [here](./extra-package-deployment.md)


## Important Security Notice

All Developer and Quick Start Guides in this repo are intended to deploy environments for development, demonstration, and learning purposes. There are practices that are bad for security, but make perfect sense for these use cases: using of default values, minimal configuration, tinkering with new functionality that could introduce a security misconfiguration, and even purposefully using insecure passwords and disabling security measures like Kyverno for convenience. Many applications have default username and passwords combinations stored in the public git repo, these insecure default credentials and configurations are intended to be overridden during production deployments.

When deploying a dev/demo environment there is a high chance of deploying Big Bang in an insecure configuration. Such deployments should be treated as if they could become easily compromised if made publicly accessible.

### Recommended Security Guidelines for Dev/Demo Deployments

* Ideally, these environments should be spun up on VMs with private IP addresses that are not publicly accessible. Local network access or an authenticated remote network access solution like a VPN or [sshuttle](https://github.com/sshuttle/sshuttle#readme) should be used to reach the private network.
* DO NOT deploy publicly routable dev/demo clusters into shared VPCs (i.e., like a shared dev environment VPCs) or on VMs with IAM Roles attached. If the demo cluster were compromised, an adversary might be able to use it as a stepping stone to move deeper into an environment.
* If you want to safely demo on Cloud Provider VMs with public IPs you must follow these guidelines:
  * Prevent Compromise:
    * Use firewalls that only allow the two VMs to talk to each other and your whitelisted IP.
  * Limit Blast Radius of Potential Compromise:
    * Only deploy to an isolated VPC, not a shared VPC.
    * Only deploy to VMs with no IAM roles/rights attached.

## Network Requirements Notice

This install guide by default requires network connectivity from your server to external DNS providers, specifically the Google DNS server at `8.8.8.8`, you can test that your node has connectivity to this DNS server by running the command `nslookup google.com 8.8.8.8` (run this from the node).

If this command returns `DNS request timed out`, then you will need to follow the steps in [troubleshooting](#Troubleshooting) to change the upstream DNS server in your kubernetes cluster to your networks DNS server.

Additionally, if your network has a proxy that has custom/internal SSL certificates then this may cause problems with pulling docker images as the image verification process can sometimes fail. Ensure you are aware of your network rules and restrictions before proceeding with the installation in order to understand potential problems when installing.

## Important Background Contextual Information

`BLUF:` This quick start guide optimizes the speed at which a demonstrable and tinker-able deployment of Big Bang can be achieved by minimizing prerequisite dependencies and substituting them with quickly implementable alternatives. Refer to the [Customer Template Repo](https://repo1.dso.mil/big-bang/customers/template) for guidance on production deployments.

`Details of how each prerequisite/dependency is quickly satisfied:`  

* **Operating System Prerequisite:** Ubuntu is presumed by the guide and all supporting scripts. Any linux distribution that supports Docker can be made to run k3d or kubernetes, but this guide presumes Ubuntu for the sake of efficiency.
* **Operating System Pre-configuration:** This quick start includes easy paste-able commands to quickly satisfy this prerequisite.
* **Kubernetes Cluster Prerequisite:** is implemented using k3d (k3s in Docker)
* **Default Storage Class Prerequisite:** k3d ships with a local volume storage class.
* **Support for automated provisioning of Kubernetes Service of type LB Prerequisite:** is implemented by taking advantage of k3d's ability to easily map port 443 of the VM to port 443 of a Dockerized LB that forwards traffic to a single Istio Ingress Gateway. Important limitations of this quick start guide's implementation of k3d to be aware of:
  * Multiple Ingress Gateways aren't supported by this implementation as they would each require their own LB, and this trick of using the host's port 443 only works for automated provisioning of a single service of type LB that leverages port 443.
  * Multiple Ingress Gateways makes a demoable/tinkerable KeyCloak and locally hosted SSO deployment much easier.
  * Multiple Ingress Gateways can be demoed on k3d if configuration tweaks are made, MetalLB is used, and you are developing using a local Linux Desktop. (network connectivity limitations of the implementation would only allow a the web browser on the k3d host server to see the webpages.)
  * If you want to easily demo and tinker with Multiple Ingress Gateways and Keycloak, then MetalLB + k3s (or another non-Dockerized Kubernetes distribution) would be a happy path to look into. (or alternatively create an issue ticket requesting prioritization of a keycloak quick start or better yet a Merge Request.)
* Access to Container Images Prerequisite is satisfied by using personal image pull credentials and internet connectivity to <https://registry1.dso.mil>
* Customer Controlled Private Git Repo Prerequisite isn't required due to substituting declarative git ops installation of the Big Bang Helm chart with an imperative helm cli based installation.
* Encrypting Secrets as code Prerequisite is substituted with clear text secrets on your local machine.
* Installing and Configuring Flux Prerequisite: Not using GitOps for the quick start eliminates the need to configure flux, and installation is covered within this guide.
* HTTPS Certificate and hostname configuration Prerequisites: Are satisfied by leveraging default hostname values and the demo HTTPS wildcard certificate that's uploaded to the Big Bang repo, which is valid for *.bigbang.dev, *.admin.bigbang.dev, and a few others. The demo HTTPS wildcard certificate is signed by the Lets Encrypt Free, a Certificate Authority trusted on the public internet, so demo sites like grafana.bigbang.dev will show a trusted HTTPS certificate.
* DNS Prerequisite: is substituted by making use of your workstation's Hosts file.

## Troubleshooting
This section will provide guidance for troubleshooting problems that may occur during your Big Bang installation and instructions for additional configuration changes that may be required in restricted networks. 

### Changing CoreDNS upstream DNS server:
After completing step 5, if you are unable to connect to external DNS providers using the command `nslookup google.com 8.8.8.8`, to test the connection. Then use the steps below to change the upstream DNS server to your networks DNS server. Please note that this change will not perist after a restart of the host server therefore, if you restart or shutdown your server you will need to re-apply these changes to CoreDNS. 

1. Open config editor to change the CoreDNS pod configuration.

    ```shell
    kubectl -n kube-system edit configmaps CoreDNS -o yaml 
    ```

1. Change: 

    ```plaintext
    forward . /etc/resolv.conf
    ```

    To:

    ```plaintext
    forward . <DNS Server IP>
    ```

1. Save changes in editor (for vi use `:wq`).

1. Verify changes in terminal output that prints new config 

### Useful Commands for Obtaining Detailed Logs from Kubernetes Cluster or Containers

* Print all pods including information related to the status of each pod.
	```shell
	kubectl get pods --all-namespaces
	```
* Print logs for specified pod.
	```shell 
	kubectl logs <pod name> -n=<namespace of pod> 
	```
* Print a dump of relevent information for debugging and diagnosing your kubernetes cluster.
	```shell
	kubectl cluster-info dump
	```

### Documentation References for Command Line Tools Used

* Kubectl - https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands 
* k3d - https://k3d.io/v5.5.1/usage/k3s/
* Docker - https://docs.docker.com/desktop/linux/troubleshoot/#diagnosing-from-the-terminal
* Helm - https://helm.sh/docs/helm/helm/

### NeuVector "Failed to Get Container"

If the NeuVector pods come online but give errors like:

```shell
ERRO|AGT|container.(*containerdDriver).GetContainer: Failed to get container - error=container "4d9a6e20883271ed9f921e86c7816549e9731fbd74cefa987025f27b4ad59fa1" in namespace "k8s.io │
ERRO|AGT|main.main: Failed to get local device information - error=container "4d9a6e20883271ed9f921e86c7816549e9731fbd74cefa987025f27b4ad59fa1" in namespace "k8s.io": not found 
```

It could be because Ubuntu prior to 21 ships with cgroup v1 by default, and NeuVector on cgroup v1 with containerd doesn't work well. To check if your installation is running cgroup v1, run:

```shell
cat /sys/fs/cgroup/cgroup.controllers
```

If you get a "No such file or directory", that means its running v1, and needs to be running v2. Follow the documentation here - https://rootlesscontaine.rs/getting-started/common/cgroup2/#checking-whether-cgroup-v2-is-already-enabled to enable v2

### "Too Many Open Files"

If the NeuVector pods fail to open, and you look at the K8s logs only to find that it's giving the "too many open files" error, you'll need to increase your inotify max's. Consider grabbing your current fs.inotify.max values and increasing them like the following

```shell
sudo sysctl fs.inotify.max_queued_events=616384
sudo sysctl fs.inotify.max_user_instances=512
sudo sysctl fs.inotify.max_user_watches=501208
```
### Failed to provide IP to istio-system/public-ingressgateway

As one option to provide IP to the istio-system/public-ingressgateway, metallb can be run. The following steps will demonstrate a standard configuration.

```
bash quickstart.sh
  -H YOUR_VM_IP \
  -U YOUR_VM_SSH_USERNAME \
  -K YOUR_VM_SSH_KEY_FILE_PATH \
  -R LOCATION_ON_FILESYSTEM_TO_CHECK_OUT_BIGBANG_CODE \
  -m
```

### WSL2 

This section will provide guidance for troubleshooting problems that may occur during your Big Bang installation specifically involving WSL2.

#### NeuVector "Failed to Get Container"

In you receive a similar error to the above "Failed to get container" with NeuVector it could be because of the cgroup configurations in WSL2. WSL2 often tries to run both cgroup and cgroup v2 in a unified manner which can confuse docker and affect deployments. To remedy this you need to create a .wslconfig file in the C:\Users\<UserName>\ directory.  In this file you need to add the following:

```shell
[wsl2]
kernelCommandLine = cgroup_no_v1=all
```

Once created you need to restart wsl2.

If this doesn't remedy the issue and the cgroup.controllers file is still located in the /sys/fs/cgroup/unified directory you may have to modify /etc/fstab and add the following:

```shell
cgroup2 /sys/fs/cgroup cgroup2 rw,nosuid,nodev,noexec,relatime,nsdelegate 0 0
```

#### Container Fails to Start: "Not Enough Memory"

Wsl2 limits the amount of memory available to half of what your computer has. If you have 32g or less (16g or less available) this is often not enough to run all of the standard big bang services. If you have more available memory you can modify the initial limit by modifying (or creating) the C:\Users\<UserName>\.wslconfig file by adding:

```shell
[wsl2]
memory=24GB
```
