# Super-Cluster

GitOps-managed Kubernetes fleet — Cluster API (CAPI) + Flux + Sveltos.

## Repository Structure

```
clusters/
├── child/                        # Child cluster definitions (CAPI manifests)
│   ├── kustomization.yaml
│   └── child-1/
│       ├── cluster.yaml          # CAPI Cluster, KCP, MachineDeployment
│       ├── kustomization.yaml
│       └── apps/                 # Per-cluster app deployments
│           └── kustomization.yaml
└── management/                   # Management cluster config (Flux-synced)
    ├── kustomization.yaml
    ├── child-1-apps.yaml         # Flux Kustomization for child-1 workloads
    ├── remote-child-kustomization.yaml  # Flux Kustomization for CAPI clusters
    ├── flux-operator/            # Flux operator + instance definitions
    │   ├── flux-instance.yaml
    │   ├── flux-web-nodeport.yaml
    │   └── git-secret.yaml       # Template (\${GH_PAT} injected by CI)
    └── sveltos/                  # Sveltos ClusterProfiles
        ├── kustomization.yaml
        ├── clusterprofile-baseline.yaml
        ├── clusterprofile-capi-bootstrap.yaml (Cilium CNI)
        ├── clusterprofile-monitoring.yaml
        ├── child-1-sveltoscluster.yaml
        ├── sveltos-addon-controller.yaml    # Pinned manifest
        └── crds/                           # Pinned libsveltos CRDs
```

## Bootstrap

GitHub Actions workflow: `.github/workflows/provision-capi-management-cluster.yml`

The workflow handles:
1. K3s installation on the VPS
2. Docker (required for CAPD)
3. `clusterctl init` with pinned CAPI v1.13.4
4. Flux Operator + FluxInstance
5. Sveltos addon-controller (pinned manifest in-repo)
6. Child cluster kubeconfig injection

After bootstrap, everything is GitOps-driven:
- **CAPI manifests**: Edit `clusters/child/*/cluster.yaml` -> Flux syncs -> CAPI provisions
- **Add-ons**: Edit Sveltos ClusterProfiles -> Flux syncs -> Sveltos deploys
- **Apps**: Add manifests to `clusters/child/*/apps/`

## Current Versions

| Component | Version | Managed By |
|---|---|---|
| Cluster API | v1.13.4 | clusterctl (workflow) |
| CAPD | v1.13.4 | clusterctl (workflow) |
| Flux | 2.x | Flux Operator (OCI) |
| Flux Operator | v0.54.1 | Manifest |
| Sveltos | v1.13.0 | Pinned manifest |
| Cilium | 1.19.6 | Sveltos ClusterProfile |
| cert-manager | v1.15.0 | Sveltos ClusterProfile |
| metrics-server | v0.7.1 | Sveltos ClusterProfile |
| kube-prometheus-stack | 60.0.0 | Sveltos ClusterProfile |
| Loki | 2.9.0 | Sveltos ClusterProfile |

## Adding a New Child Cluster

1. Copy `clusters/child/child-1/` to `clusters/child/<name>/`
2. Edit `cluster.yaml` (name, version, replicas)
3. Add `<name>` to `clusters/child/kustomization.yaml`
4. Create `clusters/management/sveltos/<name>-sveltoscluster.yaml`
5. Commit -> Flux syncs -> CAPI provisions
