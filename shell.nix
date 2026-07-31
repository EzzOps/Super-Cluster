{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [
    kubectl           # Kubernetes CLI
    helm              # Helm — installs ArgoCD (bootstrap layer)
    sshpass           # SSH with password auth (for VPS access)
  ];

  shellHook = ''
    echo "🔧 Nix shell ready — kubectl, helm, sshpass loaded"
    echo "   ClusterCTL is fetched separately (not in nixpkgs)"
  '';
}
