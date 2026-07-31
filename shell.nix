{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [
    kubectl           # Kubernetes CLI
    sshpass           # SSH with password auth (for VPS access)
  ];
  # NOTE: helm is NOT here — GitHub ubuntu-latest runners ship helm preinstalled
  #       (used by the ArgoCD install step, which runs outside nix-shell).
  shellHook = ''
    echo "🔧 Nix shell ready — kubectl, sshpass loaded"
    echo "   ClusterCTL is fetched separately (not in nixpkgs)"
  '';
}
