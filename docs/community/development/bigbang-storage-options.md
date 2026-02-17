# Big Bang Storage Options Guide

This document provides guidance on storage options for Big Bang deployments, including:
- Cloud Service Provider (CSP) managed storage (recommended for production)
- In-cluster Kubernetes storage (primarily for air-gapped or disconnected environments)
- Cloud-native object storage services (in-cluster)
- External storage services for Big Bang applications (e.g., GitLab, Mattermost, SonarQube)

> **Recommendation:** For production systems running in AWS, Azure, or GCP, prefer **CSP-managed storage services** wherever possible.  
> In-cluster storage solutions are most appropriate for **air-gapped** or **restricted** environments where managed services are not available. The Big Bang team validates Big Bang supported applications against CSP database services primarily AWS RDS. While we do update the versions of the database dependencies in the sub charts, we do not validate the Big Bang upgrade path using those dependencies. If using in-cluster databases, we recommend deploying database charts separate from those included Big Bang packages.

---

## Storage Categories in Big Bang

Big Bang workloads typically require one or more of the following storage types:

### Block Storage (RWO)
Used for:
- Databases
- Stateful app volumes (e.g., GitLab components, Mattermost file storage)
- SonarQube data volumes

### File Storage (RWX)
Used for:
- Shared filesystem workloads
- Some legacy app patterns
- High-availability file shares

### Object Storage (S3-compatible)
Used for:
- Backups
- Artifacts
- GitLab object storage (LFS, uploads, packages, registry)
- Mattermost file storage
- Velero backups

---

## Recommended Approach (Production)

### In CSP environments (AWS, Azure, GCP)
Use:
- CSP CSI drivers for Kubernetes PersistentVolumes
- CSP-managed databases (RDS, Cloud SQL, etc.)
- CSP-managed object storage (S3, GCS, Azure Blob)
- CSP-managed file services where needed (EFS, Azure Files)

This reduces operational burden and improves:
- Availability
- Performance consistency
- Patch/upgrade responsibility
- Disaster recovery options

---

## In-Cluster Storage Options (Airgap / Disconnected)

In-cluster storage is most common when:
- You cannot use CSP-managed services
- You are running on-prem, bare metal, or tactical edge
- You are in IL4/IL5/IL6-style disconnected environments
- You need storage that works entirely inside Kubernetes

---

# 1. Kubernetes CSI Options (PersistentVolumes)

These options provide Kubernetes-native block and/or file volumes.

## CSP CSI Drivers (Recommended for Production in Cloud)

### AWS EBS CSI (Block / RWO)
- Best for most stateful workloads on EKS
- Easy to operate
- Strong integration with AWS
- Does **not** provide RWX (use EFS CSI for RWX)

### AWS EFS CSI (File / RWX)
- Shared file system for RWX workloads
- Often used for workloads requiring shared mounts

### Azure Disk CSI (Block / RWO)
- Default block storage for AKS
- Good for most stateful workloads

### Azure Files CSI (File / RWX)
- RWX support via SMB/NFS depending on configuration

### GCP Persistent Disk CSI (Block / RWO)
- Standard block storage for GKE

---

## In-Cluster CSI (Airgap / On-Prem)

### Rook + Ceph (Block + File + Object)
**Best fit for:** production-grade airgapped clusters with dedicated storage nodes.

Provides:
- RBD (block volumes / RWO)
- CephFS (file volumes / RWX)
- RGW (S3-compatible object storage)

Pros:
- Most complete storage platform for disconnected environments
- Mature ecosystem
- Strong performance when properly designed

Cons:
- Operational complexity
- Requires careful sizing and failure domain planning

---

### Longhorn (Block + RWX via NFS)
**Best fit for:** small-to-medium disconnected clusters, simpler operations.

Pros:
- Easy installation and UI
- Great day-2 operational experience
- Built-in backups and snapshot support

Cons:
- RWX typically implemented via NFS layer
- Not as scalable as Ceph for large clusters

---

### OpenEBS (Local PV / cStor / Mayastor)
**Best fit for:** teams that want composable storage and local PV patterns.

Pros:
- Flexible designs
- Strong for local PV patterns and high-performance setups

Cons:
- Operational model varies by engine
- Requires careful selection (not a single “one size fits all” solution)

---

### NFS CSI (External or In-Cluster NFS)
**Best fit for:** simple RWX needs in disconnected environments.

Pros:
- Very simple
- Easy to debug

Cons:
- Not ideal for performance-sensitive or HA requirements
- Often becomes a bottleneck

---

# 2. In-Cluster Object Storage (S3-Compatible)

Object storage is often required for:
- Velero backups
- GitLab object storage (recommended)
- Mattermost file storage
- Harbor registry storage (depending on design)

## MinIO (no longer maintained upstream)
**Best fit for:** general-purpose S3-compatible storage inside Kubernetes.

Pros:
- Widely used and well documented
- Supports distributed mode for HA
- Works well for airgap

Cons:
- Still requires operational ownership (upgrades, monitoring, disks)
- Minio open source project no longer maintained upstream and will soon be removed from Big Bang ecosystem

---

## Garage (S3-Compatible)
**Best fit for:** edge/distributed environments with object-first storage needs. Soon to be substituted for Minio in Big Bang packages where S3 compatible storage is needed as a chart dependency.

Pros:
- Designed for distributed and failure-tolerant object storage
- Lightweight compared to Ceph

Cons:
- Less common in Kubernetes enterprise environments
- Operational maturity varies by organization

---

## Ceph RGW (via Rook-Ceph)
**Best fit for:** environments already using Ceph for PVs.

Pros:
- Consolidated storage platform (block + file + object)
- Good for larger deployments

Cons:
- More complex than MinIO

---

# 3. External CSP Storage Options for Big Bang Applications (Recommended)

Many Big Bang apps support externalizing their storage dependencies. This is strongly recommended in production cloud environments.

---

## Common External Storage Services

### Object Storage (Recommended)
- **AWS S3**
- **Azure Blob Storage**
- **Google Cloud Storage**

### Managed Databases (Strongly Recommended)
- **AWS RDS** (Postgres/MySQL)
- **Azure Database for PostgreSQL**
- **Cloud SQL**
- **Aurora** (where appropriate)

### Managed File Storage (When Needed)
- **AWS EFS**
- **Azure Files**
- **Filestore (GCP)**

---

# 4. Application-Specific Storage Recommendations

This section highlights common Big Bang applications and recommended storage patterns.

---

## GitLab

GitLab typically requires:
- PostgreSQL
- Redis
- Object storage (highly recommended)
- PersistentVolumes for internal components (if not fully externalized)

### Recommended (Production in CSP)
- PostgreSQL: **AWS RDS (Postgres)**
- Object Storage: **AWS S3**
- Redis: **ElastiCache (optional, if supported)**
- PVs: **EBS CSI** for remaining stateful components

**Why this is preferred:**
- GitLab is storage-heavy and operationally complex
- Offloading database + object storage reduces risk significantly

### Recommended (Airgap / Disconnected)
- PostgreSQL: in-cluster (Zalando Postgres Operator or Bitnami)
- Object Storage: MinIO or Ceph RGW
- PVs: Rook-Ceph or Longhorn

---

## Mattermost

Mattermost typically requires:
- PostgreSQL database
- File storage (object storage recommended)
- PersistentVolume for local state (minimal)

### Recommended (Production in CSP)
- PostgreSQL: **AWS RDS**
- File storage: **S3**
- Optional: EFS (only if object storage is not viable)

### Recommended (Airgap / Disconnected)
- PostgreSQL: in-cluster
- File storage: MinIO or Ceph RGW
- PVs: Rook-Ceph or Longhorn

---

## SonarQube

SonarQube typically requires:
- PostgreSQL
- PersistentVolume for data and extensions

### Recommended (Production in CSP)
- PostgreSQL: **AWS RDS**
- PV: **EBS CSI**

### Recommended (Airgap / Disconnected)
- PostgreSQL: in-cluster
- PV: Rook-Ceph or Longhorn

---

## Keycloak
Keycloak typically requires:
- PostgreSQL
- PersistentVolume is optional depending on deployment mode

### Recommended (Production in CSP)
- PostgreSQL: AWS RDS / managed Postgres

### Recommended (Airgap / Disconnected)
- PostgreSQL: in-cluster
- PV: if required, use Rook-Ceph or Longhorn

---

## Harbor (if deployed)
Harbor typically requires:
- Database
- Redis
- Object storage (preferred)
- PVs depending on configuration

### Recommended (Production in CSP)
- Database: managed Postgres
- Object storage: S3

### Recommended (Airgap / Disconnected)
- Database: in-cluster Postgres
- Object storage: MinIO or Ceph RGW

---

# 5. Big Bang Backup Storage (Velero)

Velero is commonly used for backup and restore.

## Recommended (Production in CSP)
- Backup target: S3 / GCS / Azure Blob

## Recommended (Airgap / Disconnected)
- Backup target: MinIO or Ceph RGW

---

# 6. Summary Recommendations

## Default Recommendations by Environment

### AWS / Azure / GCP (Production)
Use:
- CSP CSI drivers for PVs
- Managed databases (RDS / Cloud SQL)
- CSP object storage (S3 / GCS / Blob)
- Managed file storage only when required (EFS / Azure Files)

### Airgapped / On-Prem / Disconnected
Use:
- Rook-Ceph for full storage platform (block + file + object)
- Longhorn for simpler operations and smaller clusters
- MinIO for S3-compatible object storage
- In-cluster PostgreSQL for app databases

---

## General Rules of Thumb

- Prefer **object storage** over shared RWX file systems when the application supports it.
- Prefer **managed databases** over in-cluster databases in production cloud environments.
- Avoid building a “mini cloud” inside Kubernetes unless you must (airgap).
- If you run Ceph, treat it as a platform component requiring dedicated operations and monitoring.

---

# 7. Future Enhancements (Optional)

This document can be extended with:
- Reference architectures (AWS / on-prem)
- StorageClass examples for each CSI
- Performance and sizing guidance
- Operational checklists (upgrades, DR, monitoring)
- Known Big Bang integration notes and gotchas