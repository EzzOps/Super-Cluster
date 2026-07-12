{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [
    kubectl           # Kubernetes CLI
    fluxcd            # Flux CD / GitOps toolkit
    sshpass           # SSH with password auth (for VPS access)
  ];

  # Silence any Nix warnings about impure eval
  shellHook = ''
    echo "🔧 Nix shell ready — kubectl, fluxcd, sshpass loaded"
    echo "   ClusterCTL is fetched separately (not in nixpkgs)"
  '';
}
