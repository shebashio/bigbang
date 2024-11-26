# Testing repo1 CI against a dedicated runner

This page will describe how to deploy bigbang with a gitlabrunner that is connected to repo1. 

## Why
* You need to test gitlabrunner configuration against repo1
* You need to test integrating CI pipelines to infrastructure or other bigbang services. 

## How
### Request access
You will need either of these:
- Admin access to a repo on repo1
- Or access to create personal repos under your account

### Create gitlab runner and token


### Deploy a k8s cluster and install flux
by default the easiest way to test is to spin up a cluster using the k3d-dev.sh script.
you can follow the directions here: https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/developer/aws-k3d-script.md

### Deploy Big Bang
1. Create an overrides file withe following contect
```
# enable grafana alloy to push traces to
addons:
  alloy:
    enabled: true

# enable gitlabrunners for ci-tracing
  gitlabRunner:
    enabled: true
    values:
      # set the url to repo1
      gitlabUrl: https://repo1.dso.mil
      runners:
        # use custom config and remove cloneUrl paramaters
        config: |
          [[runners]]
            [runners.kubernetes]
              pull_policy = "always"
              namespace = "{{.Release.Namespace}}"
              image = "{{ printf "%s/%s:%s" .Values.runners.job.registry .Values.runners.job.repository .Values.runners.job.tag }}"
              helper_image = "{{ printf "%s/%s:%s" .Values.runners.helper.registry .Values.runners.helper.repository .Values.runners.helper.tag }}"
              image_pull_secrets = ["private-registry"]
            [runners.kubernetes.pod_security_context]
              run_as_non_root = true
              run_as_user = 1001
            [runners.kubernetes.helper_container_security_context]
              run_as_non_root = true
              run_as_user = 1001
            [runners.kubernetes.pod_labels]
              "job_id" = "${CI_JOB_ID}"
              "job_name" = "${CI_JOB_NAME}"
              "pipeline_id" = "${CI_PIPELINE_ID}"
              "app" = "gitlab-runner"
```

2. Deploy BigBang with the above override file
```
helm upgrade -i bigbang ./chart -n bigbang --create-namespace -f ./docs/assets/configs/example/policy-overrides-k3d.yaml -f ../overrides/registry-values.yaml -f ./chart/ingress-certs.yaml -f ../overrides/gitlabrunner-test.yaml
```