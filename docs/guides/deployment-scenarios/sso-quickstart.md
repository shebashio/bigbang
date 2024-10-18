# Auth Service and Keycloak SSO Quick Start Demo

[[_TOC_]]

The following shell script will create a local k3d Kubernetes cluster then install Flux and Big Bang with Keycloak enabled.

Be sure to set environment variables holding your Harbor / registry1 credentials, `REGISTRY_USERNAME` and `REGISTRY_PASSWORD` (the latter being your CLI Secret, which can be obtained at <https://registry1.dso>, logging in, then "User Profile")

1. Make sure you have a container runtime running (e.g. Docker, Colima)
1. Ensure `k3d` is [installed](https://k3d.io/v5.7.4/#install-current-latest-release)
1. Run the following commands to create a local k3d Kubernetes cluster and install Big Bang with Keycloak enabled: 

    ```shell
    export REGISTRY_USERNAME='Your_Name'
    export REGISTRY_PASSWORD='YourHarborCLISecret'
    branch='refresh-keycloak-sso-quickstart-docs'
    url="https://repo1.dso.mil/big-bang/bigbang/-/raw/${branch}/docs/guides/deployment-scenarios/sso-quickstart-resources/create_local_bigbang.sh"
    curl -fsSL "$url" | bash
    ```
1. Add the following lines to your `/etc/hosts` file:

    ```text
    127.0.0.1 keycloak.dev.bigbang.mil
    127.0.0.1 alertmanager.dev.bigbang.mil
    ```
1. Navigate to <https://keycloak.dev.bigbang.mil/> and click "Click Here" to register a new user:

    ![img.png](img.png)

If you can't reslve