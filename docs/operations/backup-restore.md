# Backup and Restore

[[_TOC_]]

GitOps preserves deployment configuration, but does not back up application data. Protect external databases, object storage, persistent volumes, and the credentials needed for recovery with the procedures supported by each service. The workflow below covers GitLab application backups.

## Gitlab Backups and Restores

### Gitlab Helm Chart Configuration

1. Follow the [Protect the Rails Secret](../configuration/production-considerations/gitlab.md#protect-the-rails-secret) guidance. Rails secrets are not included in the application backup and must be preserved separately.
2. Configure the required external services using [GitLab production considerations](../configuration/production-considerations/gitlab.md#configure-required-external-services). Provision the backup and temporary buckets and verify that Toolbox can access them; Big Bang does not create the buckets. When using `packages.gitlab.objectStorage.bucketPrefix`, use the generated bucket names reported in the Helm notes.
3. Use either `packages.gitlab.objectStorage.iamProfile` or `accessKey` and `accessSecret`, together with the endpoint/region configuration appropriate for your storage. Keep credentials in encrypted values.

To override the backup bucket names, use these **umbrella values**. Replace `BUCKET_NAME` and `TMP_BUCKET_NAME` with your backup and temporary bucket names. Both buckets must already exist:

```yaml
packages:
  gitlab:
    values:
      global:
        appConfig:
          backups:
            bucket: BUCKET_NAME
            tmpBucket: TMP_BUCKET_NAME
```

For manual backups and restores, size Toolbox's temporary disk for the backup and its extracted contents. This **umbrella values** example enables a PVC; adjust its size and storage class for your installation:

```yaml
packages:
  gitlab:
    values:
      upstream:
        gitlab:
          toolbox:
            persistence:
              enabled: true
              size: 100Gi
```

Toolbox settings belong beneath `packages.gitlab.values.upstream`; `global` settings remain beneath `packages.gitlab.values.global`. See the [upstream Toolbox values for chart 10.4.2](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/v10.4.2/charts/gitlab/charts/toolbox/values.yaml) and [Toolbox configuration](https://docs.gitlab.com/charts/charts/gitlab/toolbox/) for the full configuration surface. Use the upstream version bundled with your deployed GitLab package.

### Backing up Gitlab

#### Manual Steps

These commands assume the Big Bang release name and namespace are both `gitlab`. Find the running Toolbox pod, substitute its name, and create an application backup:

```shell
kubectl get pods -n gitlab -l release=gitlab,app=toolbox
kubectl exec -it TOOLBOX_POD -n gitlab -- backup-utility
```

Confirm that an archive named `<backup-id>_gitlab_backup.tar` exists in the configured backup bucket. Preserve the matching Rails secrets and record the GitLab version and edition with the backup.

The command intentionally has no component exclusions. If a component is protected separately, document that recovery dependency and use one `--skip` argument per component, for example:

```shell
# Partial backup only: LFS and artifacts must be protected separately.
kubectl exec -it TOOLBOX_POD -n gitlab -- backup-utility --skip lfs --skip artifacts
```

An application archive is not a full-cluster backup. See [GitLab backup documentation](https://docs.gitlab.com/charts/backup-restore/backup/) for coverage and limitations.

#### Automatic Cron-based Backups

Enable scheduled backups through these **umbrella values**. Choose a schedule and size the backup job's disk for your data:

```yaml
packages:
  gitlab:
    values:
      upstream:
        gitlab:
          toolbox:
            backups:
              cron:
                enabled: true
                schedule: "0 2 * * *"
                persistence:
                  enabled: true
                  size: 200Gi
```

The schedule is interpreted by the cluster's CronJob configuration. Inspect the backup Jobs, their logs, and the uploaded archives to verify completion:

```shell
kubectl get cronjobs,jobs -n gitlab
kubectl logs -n gitlab job/BACKUP_JOB
```

### Restore Gitlab

Restoration replaces existing database and application data. Use the intended recovery cluster and restore to the same GitLab version and edition as the backup. Follow the [upstream restore procedure](https://docs.gitlab.com/charts/backup-restore/restore/) for that version.

1. Verify the archive, matching Rails secrets, external-service access, and sufficient Toolbox disk space. Discover the latest archive in the **configured** backup bucket, rather than assuming it is named `gitlab-backups`:

   ```shell
   aws s3api list-objects-v2 --bucket BUCKET_NAME \
     --query 'reverse(sort_by(Contents[?ends_with(Key, `_gitlab_backup.tar`)], &LastModified))[0].Key' \
     --output json
   ```

   JSON output applies the query to the combined paginated results. Confirm that the returned key is the intended backup. The backup ID is the filename portion before `_gitlab_backup.tar`, not just the numeric timestamp.

2. If you replace the Rails Secret, restart the consumers so they load the matching secret. Select deployments by labels rather than assuming a particular Sidekiq deployment name:

   ```shell
   kubectl rollout restart deployment -n gitlab -l release=gitlab,app=sidekiq
   kubectl rollout restart deployment -n gitlab -l release=gitlab,app=webservice
   kubectl rollout restart deployment -n gitlab -l release=gitlab,app=toolbox
   kubectl rollout status deployment -n gitlab -l release=gitlab,app=toolbox
   ```

3. Coordinate reconciliation before manually scaling workloads. Record the original reconciliation state, HPA configuration, and each deployment's replica count so they can be restored. Suspend the owning Flux Kustomization before its HelmReleases, otherwise a parent may undo the suspension. Substitute your owning Kustomization's name and namespace, and adapt HelmRelease names if your installation differs:

   ```shell
   flux get kustomizations -A
   flux suspend kustomization OWNER_KUSTOMIZATION -n OWNER_NAMESPACE
   flux suspend helmrelease bigbang -n bigbang
   flux suspend helmrelease gitlab -n bigbang
   ```

   Account for any other reconcilers or autoscalers that could undo maintenance changes. Follow the upstream procedure for all database clients in your installation:

   ```shell
   kubectl get deployments -n gitlab -l 'release=gitlab,app in (sidekiq,webservice,prometheus)' \
     -o custom-columns='NAME:.metadata.name,REPLICAS:.spec.replicas'
   kubectl get hpa -n gitlab
   kubectl scale deployment -n gitlab -l 'release=gitlab,app in (sidekiq,webservice,prometheus)' --replicas=0
   ```

   Confirm that those client pods have stopped before starting the restore. This selector does not stop external clients; handle them according to the upstream procedure.

4. Find the current Toolbox pod and restore from the configured backup bucket using the backup ID:

   ```shell
   kubectl get pods -n gitlab -l release=gitlab,app=toolbox
   kubectl exec -it TOOLBOX_POD -n gitlab -- backup-utility --restore -t BACKUP_ID
   ```

   The `-f` option accepts an HTTP(S), FTP, or `file:///` URL, not an `s3://` URL. To restore a locally downloaded archive instead:

   ```shell
   kubectl cp ./BACKUP_ID_gitlab_backup.tar gitlab/TOOLBOX_POD:/tmp/restore_gitlab_backup.tar
   kubectl exec -it TOOLBOX_POD -n gitlab -- backup-utility --restore -f file:///tmp/restore_gitlab_backup.tar
   ```

5. Restore each affected deployment to its recorded replica count and reinstate any changed HPA configuration. Resume only Flux resources that were running before maintenance; keep previously suspended resources suspended. For example, substitute an actual deployment name and its recorded count:

   ```shell
   kubectl scale deployment DEPLOYMENT_NAME -n gitlab --replicas=RECORDED_COUNT
   flux resume helmrelease gitlab -n bigbang
   flux resume helmrelease bigbang -n bigbang
   flux resume kustomization OWNER_KUSTOMIZATION -n OWNER_NAMESPACE
   kubectl get pods -n gitlab
   flux get helmreleases -A
   flux get kustomizations -A
   ```

6. Complete upstream post-restore steps, including runner authentication checks where applicable. Verify sign-in, repository access, and required artifacts, uploads, and integrations. Confirm that external data excluded from the application archive has also been restored.
