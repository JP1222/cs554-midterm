#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
begin_log 05-readiness.txt
TARGET_POD=$(k get pods -l app=midterm-app -o jsonpath='{.items[0].metadata.name}')
restore_readiness() {
  k exec "$TARGET_POD" -- node -e 'require("node:fs").rmSync(process.env.READINESS_BLOCK_FILE,{force:true})' >/dev/null 2>&1 || true
}
trap restore_readiness EXIT
wait_ready_endpoints 2
capture_phase 05-readiness-baseline
printf '\nSelected one replica only: %s\n' "$TARGET_POD"
run k exec "$TARGET_POD" -- node -e 'console.log("PID1: "+require("node:fs").readFileSync("/proc/1/cmdline","utf8").replaceAll("\u0000"," "))'
run service_samples
run k exec "$TARGET_POD" -- node -e 'require("node:fs").writeFileSync(process.env.READINESS_BLOCK_FILE,"Controlled readiness experiment\n")'
run k wait "pod/$TARGET_POD" --for=condition=Ready=false --timeout=60s
wait_ready_endpoints 1
capture_phase 05-readiness-failure
run k exec "$TARGET_POD" -- node -e 'console.log("PID1: "+require("node:fs").readFileSync("/proc/1/cmdline","utf8").replaceAll("\u0000"," "))'
POD_IP=$(k get pod "$TARGET_POD" -o jsonpath='{.status.podIP}')
printf '\nDiagnostic direct Pod request proves the process still serves /; this is not Service evidence:\n'
run client_get "http://$POD_IP:8080/"
printf '\nDirect /health request should now return HTTP 503:\n'
if client_get "http://$POD_IP:8080/health"; then
  printf 'ERROR: expected readiness HTTP 503\n'; exit 1
fi
printf '\nService requests should use the remaining Ready replica:\n'
run service_samples
run k describe pod "$TARGET_POD"
run k exec "$TARGET_POD" -- node -e 'require("node:fs").rmSync(process.env.READINESS_BLOCK_FILE,{force:true})'
run k wait "pod/$TARGET_POD" --for=condition=Ready --timeout=60s
wait_ready_endpoints 2
capture_phase 05-readiness-recovery
run service_samples
run k logs "$TARGET_POD" --tail=20
trap - EXIT
