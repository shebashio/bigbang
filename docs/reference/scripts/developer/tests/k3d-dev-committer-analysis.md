# k3d-dev.sh Committer Analysis

Generated from `git log --follow` on 2026-02-09. File history traces through two renames:

- `docs/assets/scripts/developer/k3d-dev.sh` (Sep 2021 — Jul 2022)
- `docs/developer/k3d-dev.sh` (Jul 2022 — Nov 2025)
- `docs/reference/scripts/developer/k3d-dev.sh` (Nov 2025 — present)

## Summary

- **87 commits** from **33 contributors** over **4+ years**
- **Zero automated tests** until this branch

## All Time (Sep 2021 — present)

| # | Committer | Commits | Era |
|---|---|---|---|
| 1 | Micah Nagel | 13 | 2022 (original buildout) |
| 2 | Danny Gershman | 11 | 2023 (EIP, k3d versions, readability) |
| 3 | Andrew Kesterson | 10 | 2025 (MetalLB default, long args, quickstart) |
| 4 | kevin.wilder | 9 | 2021–2022 (creator + early iterations) |
| 5 | Zach Callahan | 4 | 2024–2026 (istio gateways, docker group, CoreDNS) |
| 6 | Jonathan Braswell | 4 | 2023 (VPC/subnet, .kube dir, IB metallb) |
| 7 | jeffv | 3 | 2024–2025 (k8s version bumps) |
| 8 | Ben Francis | 3 | 2023 (apt, port 6443, AMI fix) |
| 9 | BB_AUTO_MR_TOKEN | 3 | automated subdomain adds |
| 10 | Rob McCarthy | 2 | 2025 (cypress, comments) |
| 11 | Christopher O'Connell | 2 | 2023 (AMI, script fix) |
| 12 | Alozie Obuh | 2 | 2024 (k8s version bumps) |
| — | *(21 others, 1 commit each)* | 21 | |

## Past 18 Months (Aug 2024 — present)

| # | Committer | Commits |
|---|---|---|
| 1 | Andrew Kesterson | 10 |
| 2 | Zach Callahan | 4 |
| 3 | BB_AUTO_MR_TOKEN | 3 |
| 4 | jeffv | 2 |
| 5 | Rob McCarthy | 2 |
| — | *(11 others, 1 each)* | 11 |

## Full Commit Log

```
2026-02-04  BB_AUTO_MR_TOKEN    thanos update to 17.3.3-bb.3
2026-01-29  Dustin Hilgaertner  Update headlamp tag 0.39.0 bb.2
2026-01-22  Andrew Kesterson    Quickstart bugfixes
2026-01-20  Zach Callahan       docs(k3d-dev): create sane coredns config for bb domains
2026-01-20  BB_AUTO_MR_TOKEN    kyvernoReporter update to 3.7.1-bb.1
2025-12-16  Jeffrey Victor      update metallb and k3d
2025-11-25  Andrew Shoell       Resolve "[SPIKE]: Identify all existing documentation"
2025-08-19  jeffv               update local k3d dev to 1.33 and k3d version to 5.8.3
2025-06-17  Jimmy Bourque       Updated script to reserve IP's for gateways and increase IP reservation range
2025-06-17  Andrew Kesterson    Support the usage of custom subnet addresses
2025-06-04  Jeremy Glover       Check for existence of SSH folder and create it if it does not exist
2025-06-04  Danilo Patrucco     Update K3d script to fix login
2025-05-28  Zach Callahan       fix(k3d-dev): handled the case where apt doesn't create the docker group
2025-04-17  Rob McCarthy        add cypress mount and permissions; update spot instance requests
2025-03-28  Andrew Kesterson    #2591, #2592, #2593
2025-03-03  Greg M              Operatorless Istio with CORE packages only
2025-02-21  Zach Callahan       feat(istio): added iterable gateways
2025-02-18  Andrew Kesterson    Update quickstart documentation, make k3d-dev reprint instructions
2025-02-14  Andrew Kesterson    #2517: Add --trace to k3d create command
2025-02-13  Andrew Kesterson    #2514: Add long argument names to k3d-dev.sh
2025-02-07  Andrew Kesterson    Make metalLB the default k3d load balancer
2025-02-04  Andrew Kesterson    #2492: Fix metallb deployments and the recreate/rebuild prompt
2025-01-29  Andrew Kesterson    Rewrite the quickstart document, refactor k3d-dev
2025-01-13  jeffv               updated k3d to 1.31 and metallb to latest
2024-12-20  Rob McCarthy        couple of spelling/comment formatting adjustments
2024-11-13  Luis Gomez          Fix K3d-dev.sh - Apply secondary allocated IP to CoreDNS Configmap
2024-11-04  Zach Callahan       Resolve "k3d-dev.sh not running userdata"
2024-10-29  bjacksonfv          Adjusted k3d-dev.sh instructions output
2024-10-29  Andrew Kesterson    Improve k3d cluster management, especially for multiple clusters
2024-09-09  Jacob Kershaw       Fixed change within k3d script
2024-09-06  BB_AUTO_MR_TOKEN    mattermost update to 9.10.1-bb.5
2024-08-06  Alozie Obuh         update to 1.30
2024-06-06  Samuel Sarnowski    Add K3D_FIX_MOUNTS=1 export for istio cni support
2024-04-03  jeffv               updating to 1.29.3
2024-03-25  Ryan Garcia         dev bigbang mil cert
2024-02-07  Alozie Obuh         update local script to 1.28
2023-11-08  Stephen Galamb      Upgrade Local Script to Kubernetes 1.27
2023-10-26  Jonathan Braswell   modify k3d-dev.sh to use ib metallb images
2023-10-03  Christopher O'Connell  Change default AMI for k3d-dev
2023-09-28  Jonathan Braswell   create .kube dir on first run of k3d-dev.sh
2023-09-15  Jonathan Braswell   fix k3d-dev.sh SUBNET_ID specifier and public ip
2023-08-30  Jonathan Braswell   make vpc and subnet configurable in k3d-dev.sh
2023-08-29  James Causey        Remove default vpc dep
2023-07-26  Michael Martin      Add Weave CNI To K3D
2023-06-27  Ben Francis         sudo apt update && sudo apt upgrade -y
2023-06-22  Ben Francis         Kill "[[ ! -z " with fire
2023-06-14  Ben Francis         Added port 6443 during private instance deployment
2023-06-06  Ben T. Francis      Fix k3d-dev.sh default AMI selection
2023-05-25  Danny Gershman      sync kubectl to k8s version and implementing checksum verification
2023-04-27  Danny Gershman      Use an Elastic IPs w/Secondary IP for Keycloak
2023-04-12  Danny Gershman      [k3d-dev.sh] using gp3 and volume encryption
2023-04-04  Danny Gershman      Override k8s version for k3d
2023-04-04  Danny Gershman      [k3d-dev.sh] Rebuild K3D cluster without instance re-creation
2023-03-27  Danny Gershman      update k3d version for dev script to 5.4.9
2023-03-24  Danny Gershman      Making k3d-dev.sh more readable and maintainable
2023-03-13  Danny Gershman      k3d update to 5.4.8, typo fix
2023-03-03  Micah Nagel         k3d dev script metallb update
2023-02-27  kevin.wilder        fix docker install
2023-02-09  Danny Gershman      update k3d-dev.sh version from 5.4.6 to 5.4.7
2023-02-07  Danny Gershman      Switching to better scriptable alternative apt-get
2023-02-03  Danny Gershman      Automatically pull the latest image that matches the current parameters
2023-01-30  Christopher O'Connell  Fix k3d-dev.sh script
2022-10-31  Micah Nagel         Change k3d dev script to run-instances API
2022-10-03  Brendon Lloyd       Add /etc/hosts file entries for other apps
2022-09-27  Micah Nagel         Add dependency tools for k3d dev script
2022-09-27  Micah Nagel         Fix k3d dev script instance setup
2022-09-23  Micah Nagel         Update dev script to k3d 5.4.6 (k3s 1.24.4-k3s1)
2022-09-23  Micah Nagel         Add sysctl/modprobe changes to k3d dev script
2022-09-23  Micah Nagel         Add sysctl changes to k3d dev script
2022-09-23  Micah Nagel         Update k3d dev script to Ubuntu Jammy (22.04.1)
2022-09-08  Micah Nagel         Dev Script: Shutdown in 8 hours + alter SSH example
2022-08-29  Micah Nagel         k3d dev script: add volumes to support twistlock defenders
2022-08-12  Micah Nagel         Simplify conditionals/DRY up the k3d dev script
2022-08-03  kevin.wilder        K3d dev script updates
2022-08-02  Brett Charrier      gateway needed for docker network when using MetalLB
2022-07-27  brandt keller        [skip ci]/update k3d script - organize environment variables
2022-07-22  kevin.wilder        K3d script update
2022-07-11  razzle              Resolve "Fix MkDocs Markdown formatting issues"
2022-06-06  Micah Nagel         Update dev script with DNS proxy instructions
2022-06-02  Micah Nagel         Update k3d dev script output with VS that exists
2022-05-27  kevin.wilder        Remove k9s from script
2022-01-27  kevin.wilder        Resolve "k3d dev script improvements"
2022-01-06  kevin.wilder        update k3d dev script
2021-12-15  evan.rush           Docs - 948 - k3d-dev.sh needs preflight/requirement checks
2021-10-12  kevin.wilder        hardcode image id instead of searching for it
2021-09-30  kevin.wilder        K3d script tweaks
2021-09-28  kevin.wilder        K3d dev script
```
