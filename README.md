# Super-Cluster

GitOps-managed Kubernetes fleet — Cluster API (CAPI) + ArgoCD + Sveltos.

## Architecture

The management cluster (K3s on the VPS) runs the GitOps control plane:

- **ArgoCD** — the GitOps engine (app-of-apps pattern), installed via Helm by CI
- **Cluster API (CAPD)** — provisions child clusters from `clusters/child/*`
- **Sveltos** — add-on delivery into child clusters (Cilium, metrics-server,
  cert-manager, monitoring) via ClusterProfiles

```
┌───────────────────────────────────────────────────────────────┐
│ Management cluster (K3s @ VPS)                                 │
│  ├─ ArgoCD (UI: NodePort :30080)                               │
│  │   ├─ bootstrap (app-of-apps → clusters/management/apps)     │
│  │   ├─ capi-child-1        → clusters/child/child-1           │
│  │   ├─ sveltos-crds        → helm chart (CRDs)                │
│  │   ├─ sveltos-addon-ctrl  → helm chart (addon-controller)    │
│  │   ├─ sveltos-profiles    → clusters/management/sveltos      │
│  │   └─ child-1-apps        → clusters/child/child-1/apps      │
│  ├─ Cluster API (CAPI + CAPD)                                  │
│  └─ Sveltos addon-controller                                   │
└──────────────┬────────────────────────────────────────────────┘
               │ ArgoCD cluster secret "child-1" (registered by CI)
        ┌──────▼──────┐
        │   child-1   │  CAPI/Docker cluster — Cilium, metrics-server,
        │  workloads  │  cert-manager, monitoring (via Sveltos)
        └─────────────┘
```

## Repository Structure

```
clusters/
├── child/                        # Child cluster definitions (CAPI manifests)
│   └── child-1/
│       ├── cluster.yaml          # CAPI Cluster, KCP, MachineDeployment
│       └── apps/                 # Workloads synced INTO child-1 by ArgoCD
└── management/                   # Management cluster config (ArgoCD-managed)
    ├── argocd/values.yaml        # argo-cd Helm chart values (bootstrap layer)
    ├── bootstrap.yaml            # Root app-of-apps Application (applied by CI)
    ├── apps/                     # Synced by bootstrap → all child Applications
    │   ├── project.yaml          # AppProject: super-cluster
    │   ├── capi-child-1.yaml     # CAPI manifests → management cluster
    │   ├── sveltos-crds.yaml     # Sveltos CRDs (Helm chart)
    │   ├── sveltos-addon-controller.yaml  # Sveltos controller (Helm chart)
    │   ├── sveltos-profiles.yaml # ClusterProfiles + SveltosCluster
    │   └── child-1-apps.yaml     # Child workloads → child-1 cluster
    └── sveltos/                  # Sveltos ClusterProfiles (plain YAML)
```

## Bootstrap

GitHub Actions workflow `.github/workflows/provision-capi-management-cluster.yml`:

1. Ensure K3s + Docker on the VPS
2. `clusterctl init` with pinned CAPI v1.13.4
3. **Decommission Flux if present** (safe order: controllers dead → CRs purged
   with finalizers stripped → namespace removed — no cascade pruning)
4. Install **ArgoCD** via Helm (chart pinned, values from the repo)
5. Apply the AppProject + root bootstrap Application (app-of-apps)
6. Wait for Sveltos + child clusters, then register child kubeconfigs:
   - `child-1-kubeconfig` secret (ns `default`) for Sveltos
   - ArgoCD cluster secret `child-1` (kubeconfig JSON) for remote syncs
7. Everything after that is pure ArgoCD reconciliation

The workflow is idempotent — safe to re-run any time.

## Day-2 Operations

- **ArgoCD UI**: `http://<VPS_IP>:30080` — user `admin`, initial password is
  printed by the workflow (also: `kubectl -n argocd get secret argocd-initial-admin-secret`)
- **Add a child cluster**: create `clusters/child/<name>/cluster.yaml` +
  `clusters/management/apps/capi-<name>.yaml` (+ `<name>-apps.yaml` for its
  workloads), push to main
- **Add workloads to child-1**: put manifests in `clusters/child/child-1/apps/`
- **Add-ons**: edit Sveltos ClusterProfiles in `clusters/management/sveltos/`
- **Sync waves** (app-of-apps): CAPI + Sveltos CRDs → addon-controller →
  ClusterProfiles → child workloads

## Current Versions

| Component | Version | Managed By |
|---|---|---|
| ArgoCD | v3.4.5 (chart 10.2.1) | Helm (workflow) |
| Cluster API | v1.13.4 | clusterctl (workflow) |
| CAPD | v1.13.4 | clusterctl (workflow) |
| Sveltos (crds chart) | 1.12.0 | ArgoCD (Helm) |
| Sveltos (controller chart) | 1.12.7 (images v1.13.0) | ArgoCD (Helm) |
| Cilium | 1.19.6 | Sveltos ClusterProfile |
