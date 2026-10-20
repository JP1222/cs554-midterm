#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
begin_log 03-pod-replacement.txt
capture_phase 03-before-delete
TARGET_POD=$(k get pods -l app=midterm-app -o jsonpath='{.items[0].metadata.name}')
printf '\nDeleting application Pod: %s\n' "$TARGET_POD"
run k delete pod "$TARGET_POD" --wait=true
run k rollout status deployment/midterm-app --timeout=120s
wait_ready_endpoints 2
capture_phase 03-after-replacement
if k get pod "$TARGET_POD" >/dev/null 2>&1; then
  printf 'Deleted Pod still exists unexpectedly\n'; exit 1
fi
printf 'Verified original Pod no longer exists; replacement is shown above.\n'
run service_samples
