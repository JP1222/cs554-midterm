#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
# Only this assignment's Compose project and k3d cluster are removed.
docker compose down
k3d cluster delete cs554-midterm
rm -f .runtime/kubeconfig
printf 'Project containers and cluster removed. Source and evidence retained.\n'
