#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
[ "$(uname -s)" = Linux ] || { echo 'Run this inside the Ubuntu VM.'; exit 1; }
case "$(uname -m)" in aarch64|arm64) arch=arm64;; x86_64) arch=amd64;; *) echo 'Unsupported architecture'; exit 1;; esac
mkdir -p .tools .runtime evidence
curl -fL --retry 2 -o .tools/k3d "https://github.com/k3d-io/k3d/releases/download/v5.9.0/k3d-linux-$arch"
curl -fsSL -o .runtime/k3d-checksums.txt https://github.com/k3d-io/k3d/releases/download/v5.9.0/checksums.txt
expected=$(awk -v name="k3d-linux-$arch" '$2 == name {print $1}' .runtime/k3d-checksums.txt)
[ -n "$expected" ]
printf '%s  .tools/k3d\n' "$expected" | sha256sum -c -
curl -fL --retry 2 -o .tools/kubectl "https://dl.k8s.io/release/v1.35.5/bin/linux/$arch/kubectl"
curl -fsSL -o .runtime/kubectl.sha256 "https://dl.k8s.io/release/v1.35.5/bin/linux/$arch/kubectl.sha256"
printf '%s  .tools/kubectl\n' "$(cat .runtime/kubectl.sha256)" | sha256sum -c -
chmod +x .tools/k3d .tools/kubectl
.tools/k3d version
.tools/kubectl version --client
