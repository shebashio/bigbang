#!/usr/bin/env bash
set -euo pipefail

cat << EOF > ~/ib_creds.yaml
registryCredentials:
  registry: registry1.dso.mil
  username: "\$REGISTRY1_USERNAME"
  password: "\$REGISTRY1_PASSWORD"
EOF

cat << EOF > ~/demo_values.yaml
elasticsearchKibana:
  values:
    kibana:
      count: 1
      resources:
        requests:
          cpu: 1m
          memory: 1Mi
        limits:
          cpu: null  # nonexistent cpu limit results in faster spin up
          memory: null
    elasticsearch:
      master:
        count: 1
        resources:
          requests:
            cpu: 1m
            memory: 1Mi
          limits:
            cpu: null
            memory: null
      data:
        count: 1
        resources:
          requests:
            cpu: 1m
            memory: 1Mi
          limits:
            cpu: null
            memory: null

clusterAuditor:
  values:
    resources:
      requests:
        cpu: 1m
        memory: 1Mi
      limits:
        cpu: null
        memory: null

kyverno:
  enabled: true
  values:

kyvernoPolicies:
  enabled: true
  values:
    exclude:
      any:
        - resources:
            namespaces:
            - kube-system
            # avoid touching anything in istio-system to avoid interfering with k3d
            - istio-system

gatekeeper:
  enabled: false

clusterAuditor:
  enabled: false

istio:
  values:
    values:
      global:
        proxy:
          resources:
            requests:
              cpu: 0m
              memory: 0Mi
            limits:
              cpu: 0m
              memory: 0Mi

twistlock:
  enabled: false
EOF

helm upgrade --install bigbang $HOME/bigbang/chart \
  --values https://repo1.dso.mil/big-bang/bigbang/-/raw/master/chart/ingress-certs.yaml \
  --values $HOME/ib_creds.yaml \
  --values $HOME/demo_values.yaml \
  --namespace=bigbang --create-namespace