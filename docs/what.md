# What is Big Bang?
**[I want to build this page out more. It's short compared to the other sections, and in some respects, it should be the most detailed]**

Big Bang is an umbrella Helm Chart that is used to deploy a DevSecOps Platform on a Kubernetes Cluster. The DevSecOps Platform is composed of application packages of open-source and commercial software, which are bundled as helm charts that leverage Iron Bank hardened container images. It leverages Flux CD for GitOps-based deployments and provides several key features to increase the improve the deployment and maintenance experience of cloud-native applications. 
The Big Bang Helm Chart deploys gitrepository and helmrelease Custom Resources to a Kubernetes Cluster running the Flux GitOps Operator, these can be seen using `kubectl get gitrepository,helmrelease -n=bigbang.` Flux then installs the helm charts defined by the Custom Resources into the cluster.
It has a values.yaml file that does two main things:
* Defines which DevSecOps Platform packages/helm charts will be deployed.
* Defines what input parameters will be passed through to the chosen helm charts.

You can see what applications are part of the platform by checking the following resources:
* [packages.md](../packages/index.md) lists the packages and organizes them in categories.
* [Release Notes](https://repo1.dso.mil/big-bang/bigbang/-/releases) lists the packages and their versions.
* For a code based source of truth, you can check [Big Bang's default values.yaml](../../chart/values.yaml), and `[CTRL] + [F]`, `"repo:"`, to quickly iterate through the list of applications supported by the Big Bang team.
* [Big Bang Universe](https://universe.bigbang.dso.mil) provides an interactive visual of all packages in Core, Addons, and Community as described in [Big Bang README](../../README.md#usage--scope)

Big Bang's DevSecOps platform's key features can be broken down into five categories of focus: Zero Trust Security, Compliance by Design, Observability Stack, Service Mesh, and Developer Experience. 

**[We are going to build out each of these sections to offer more information and value.]**
### Zero Trust Security 
*Big Bang adheres to Zero Trust Security, providing an architecture with access limited to only the minimum amount of permissions that users need to perform their duties effectively. In order to achieve maximum Zero Trust adherance, we offer the following features:*
- ***Feature 1:** Explain feature*

Built-in security controls with defense-in-depth architecture
### Compliance by Design
Big Bang 

Implementation of the DoD DevSecOps Reference Architecture and industry standards
### Observability Stack 
Comprehensive monitoring, logging, and tracing capabilities 
### Service Mesh
Istio-based secure service-to-service communication
### Developer Experience
Integrated CI/CD pipelines and development tools

## What *isn't* Big Bang?

Big Bang by itself is not intended to be an End-to-End Secure Kubernetes Cluster Solution, but rather a reusable secure component/piece of a full solution.
A Secure Kubernetes Cluster Solution will have multiple components that can each be swappable and in some cases considered optional depending on use case and risk tolerance:

Some example of potential components in a full end-to-end solution include:
* Ingress traffic protection
  * Platform One's Cloud Native Access Point (CNAP) is one solution.
  * CNAP can be swapped with an equivalent, or considered optional in an internet disconnected setup.
* Hardened Host OS
* Hardened Kubernetes Cluster
    * Big Bang assumes Bring your own Cluster (BYOC)
    * The Big Bang team recommends consumers who are interested in a full solution, partner with Vendors of Kubernetes Distributions to satisfy the prerequisite of a Hardened Kubernetes Cluster.
* Hardened Applications running on the Cluster
    * Iron Bank provides hardened containers that helps solve this component.
    * Big Bang utilizes the hardened containers in Iron Bank.