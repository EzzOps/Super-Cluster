# child-1 workloads

Manifests in this directory are synced **into the child-1 cluster** by the
ArgoCD application `child-1-apps` (destination: cluster `child-1`, namespace
`default`).

Add any workload YAML here and push to main — ArgoCD applies it to child-1.

> ArgoCD ignores non-manifest files (README, .gitkeep), so this directory
> can stay empty without breaking the sync.
