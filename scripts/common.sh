#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
export PATH="$ROOT/.tools:$PATH"
export KUBECONFIG="$ROOT/.runtime/kubeconfig"
export K3D_FIX_DNS=0
mkdir -p evidence .runtime
run() {
  printf '\n$'
  printf ' %q' "$@"
  printf '\n'
  "$@"
}
begin_log() {
  local log="evidence/$1"
  exec > >(tee "$log") 2>&1
  printf 'UTC: %s\n' "$(date -u +%FT%TZ)"
  printf 'Working directory: %s\n' "$ROOT"
}
k() { kubectl -n cs554-midterm "$@"; }
client_get() {
  k exec evidence-client -- node -e '
    const url = process.argv[1];
    fetch(url, {signal: AbortSignal.timeout(4000)})
      .then(async r => { console.log("HTTP " + r.status + " " + await r.text()); if (!r.ok) process.exitCode=1; })
      .catch(e => { console.error(e.name + ": " + e.message); process.exitCode=2; });
  ' "$1"
}
snapshot() {
  run k get deployment,pods,service -o wide
  run k get pods --show-labels
  run k get endpointslices -l kubernetes.io/service-name=midterm-app -o yaml
}
ready_endpoint_count() {
  k get endpointslices -l kubernetes.io/service-name=midterm-app -o json | node -e '
    let s=""; process.stdin.on("data", d=>s+=d); process.stdin.on("end",()=>{
      const data=JSON.parse(s); console.log(data.items.flatMap(x=>x.endpoints||[]).filter(x=>x.conditions?.ready===true).length);
    });'
}
wait_ready_endpoints() {
  local expected="$1"
  for attempt in {1..40}; do
    if [ "$(ready_endpoint_count)" = "$expected" ]; then
      printf 'Verified ready Service endpoints: %s\n' "$expected"
      return 0
    fi
    sleep 1
  done
  printf 'Expected %s ready endpoints, got %s\n' "$expected" "$(ready_endpoint_count)"
  return 1
}
capture_phase() {
  local phase="$1"
  k get pods -l app=midterm-app -o json > "evidence/$phase-pods.json"
  k get endpointslices -l kubernetes.io/service-name=midterm-app -o json > "evidence/$phase-endpointslices.json"
  snapshot
}
service_samples() {
  k exec evidence-client -- node -e '
    (async()=>{
      for(let i=0;i<8;i++) {
        const r=await fetch("http://midterm-app/", {headers:{Connection:"close"},signal:AbortSignal.timeout(4000)});
        console.log("HTTP " + r.status + " " + await r.text());
        if(!r.ok)process.exitCode=1;
      }
    })().catch(e=>{console.error(e);process.exitCode=2});'
}
