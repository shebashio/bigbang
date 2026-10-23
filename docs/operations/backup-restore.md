# Backup and Restore

Use this guide to identify what to back up in a Big Bang deployment and find the appropriate backup and restore procedures. Big Bang-specific steps are included for GitLab.

Big Bang uses Flux to manage deployment configuration, but GitOps does not back up application data or persistent volumes.

## What to Back Up

| What | How to Protect It |
| --- | --- |
| Big Bang configuration | Maintain deployment configuration in Git and preserve the credentials and secrets needed for recovery. |
| Kubernetes resources and persistent volumes | Use a compatible backup solution, such as Velero. See [Big Bang Velero backup and restore](https://docs-bigbang.dso.mil/latest/packages/velero/docs/backup/full-cluster-backup/). |
| GitLab application data | Use the GitLab Toolbox `backup-utility`. See [GitLab Backup and Restore](#gitlab-backup-and-restore). |
| GitLab Rails secrets | Back up separately from application data and store securely outside the cluster. |
| External databases, object storage, and other stateful services | Follow the backup procedures supported by each service. |

**Important:** Kubernetes resource backups do not necessarily include all application data. Confirm backup coverage, persistent-volume support, and application consistency requirements before relying on a backup for recovery.

## GitLab Backup and Restore

GitLab uses the Toolbox `backup-utility` to create and restore application backups.

### Before You Begin

Before backing up or restoring GitLab:

- **Protect Rails secrets.** GitLab backups do not include them. Preserve the secrets required to decrypt restored application data.
- **Configure backup storage.** Provision the required backup and temporary object-storage buckets and ensure the Toolbox can access them. Big Bang does not create external buckets.
- **Verify storage authentication.** Configure `packages.gitlab.objectStorage.iamProfile` or both `packages.gitlab.objectStorage.accessKey` and `packages.gitlab.objectStorage.accessSecret`, as appropriate for your environment. Set `packages.gitlab.objectStorage.bucketPrefix` or configure the backup bucket name explicitly.
- **Check Toolbox storage.** Ensure the Toolbox has sufficient temporary disk space for backup creation and extraction. For manual backups, verify that the temporary directory has the required persistent storage. See [GitLab Toolbox configuration](https://docs.gitlab.com/charts/charts/gitlab/toolbox/).
- **Confirm backup coverage.** Identify external PostgreSQL, Redis or Valkey, object storage, and other services that require separate protection.

For Big Bang-specific configuration, bucket naming, and Rails secret management, see [GitLab Production Considerations](../configuration/production-considerations/gitlab.md).

### Back Up GitLab

Find the Toolbox pod and create a backup:

```shell
kubectl get pods -n gitlab -l release=gitlab,app=toolbox
kubectl exec -it <toolbox-pod-name> -n gitlab -- backup-utility
```

The backup archive is uploaded to the configured backup bucket as `<backup-id>_gitlab_backup.tar`. Confirm that the archive exists before relying on the backup.

For backup options, component exclusions, and scheduled backups, see [GitLab backup documentation](https://docs.gitlab.com/charts/backup-restore/backup/).

For scheduled backups, inspect the Jobs and their logs to confirm completion:

```shell
kubectl get jobs -n gitlab
kubectl logs -n gitlab job/<backup-job-name>
```

### Restore GitLab

**Warning:** Restoring GitLab erases existing database contents and can replace repository and object-storage data. Confirm the backup and target environment before proceeding.

Follow the [GitLab restore procedure](https://docs.gitlab.com/charts/backup-restore/restore/) for your deployed version.

1. Verify the backup archive, required external data, and matching Rails secrets. If the Rails secrets are replaced, restart the affected GitLab pods as directed by GitLab.
2. Confirm that the target GitLab version matches the backup and that the Toolbox has sufficient temporary storage.
3. Coordinate Flux reconciliation and follow GitLab's instructions to stop database clients. Record the affected deployment replica counts before scaling them down.
4. Run the restore from the Toolbox pod:

   ```shell
   kubectl exec -it <toolbox-pod-name> -n gitlab -- backup-utility --restore -t <backup-id>
   ```

5. Restore the affected deployments to their recorded replica counts and resume normal reconciliation according to your environment's recovery procedure.

The backup ID is the portion of the archive filename before `_gitlab_backup.tar`.

### Verify the Restore

After restoring GitLab:

1. Confirm that GitLab deployments and pods are healthy.
2. Verify that users can sign in, access projects and repositories, and use required external services.
3. Complete GitLab's post-restore requirements and confirm Flux resources are ready.

```shell
kubectl get pods -n gitlab
flux get all -A --status-selector ready=false
```

For reconciliation failures, see [Troubleshoot a Big Bang deployment](troubleshooting/index.md).