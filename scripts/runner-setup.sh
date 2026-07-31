#!/usr/bin/env bash
# Super-Cluster self-hosted GitHub Actions runner setup (run as root)
set -euo pipefail

REG_TOKEN="${1:?usage: $0 <registration-token>}"
RUNNER_VERSION="2.336.0"
REPO="EzzOps/Super-Cluster"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64) RUNNER_ARCH="x64" ;;
  aarch64|arm64) RUNNER_ARCH="arm64" ;;
  *) echo "unsupported arch $ARCH"; exit 1 ;;
esac

echo "==> Creating ghrunner user (NOPASSWD sudo + docker group)"
id ghrunner >/dev/null 2>&1 || useradd -m -s /bin/bash ghrunner
usermod -aG docker ghrunner 2>/dev/null || true
echo 'ghrunner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ghrunner
chmod 440 /etc/sudoers.d/ghrunner

echo "==> Installing kubectl / helm / clusterctl (system-wide)"
if ! command -v kubectl >/dev/null; then
  KUBE_VER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBE_VER}/bin/linux/${RUNNER_ARCH}/kubectl"
  chmod +x /usr/local/bin/kubectl
fi
if ! command -v helm >/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
if ! command -v clusterctl >/dev/null; then
  curl -fsSLo /usr/local/bin/clusterctl "https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.13.4/clusterctl-linux-${RUNNER_ARCH}"
  chmod +x /usr/local/bin/clusterctl
fi

echo "==> Installing actions-runner v${RUNNER_VERSION} (${RUNNER_ARCH})"
RUNNER_DIR="/home/ghrunner/actions-runner"
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"
if [ ! -f config.sh ]; then
  curl -fsSLo runner.tgz "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
  tar xzf runner.tgz
  rm -f runner.tgz
  ./bin/installdependencies.sh
fi

echo "==> Registering runner"
sudo -u ghrunner ./config.sh --url "https://github.com/${REPO}" --token "$REG_TOKEN" \
  --name "vps-runner" --labels "self-hosted,linux,${RUNNER_ARCH},vps" \
  --work "_work" --unattended --replace

echo "==> Installing runner service"
./svc.sh install ghrunner
./svc.sh start
sleep 3
./svc.sh status

echo "==> Done. Runner registered as 'vps-runner' with labels self-hosted,linux,${RUNNER_ARCH},vps"
