#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
begin_log 04-selector-failure.txt
restore_selector() { k patch service midterm-app --type=merge -p '{"spec":{"selector":{"app":"midterm-app"}}}' >/dev/null; }
trap restore_selector EXIT
wait_ready_endpoints 2
capture_phase 04-selector-baseline
run client_get http://midterm-app/
run k patch service midterm-app --type=merge -p '{"spec":{"selector":{"app":"midterm-app-mismatch"}}}'
wait_ready_endpoints 0
capture_phase 04-selector-failure
printf '\nA new in-cluster client request depends on the Service selector:\n'
if client_get http://midterm-app/; then
  printf 'ERROR: expected connectivity failure\n'; exit 1
else
  printf 'Observed expected client failure while application Pods remain Ready.\n'
fi
run k patch service midterm-app --type=merge -p '{"spec":{"selector":{"app":"midterm-app"}}}'
wait_ready_endpoints 2
capture_phase 04-selector-recovery
run client_get http://midterm-app/
trap - EXIT
