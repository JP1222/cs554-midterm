# Experiment results

All experiments below were executed on October 15, 2026. Logs include UTC timestamps and commands. `k` means `kubectl -n cs554-midterm`; `client_get` and `service_samples` execute HTTP requests from the separate in-cluster client Pod. Their complete definitions are in [scripts/common.sh](../scripts/common.sh).

| ID | Requirement / result | Original evidence |
| --- | --- | --- |
| E0 | Ubuntu VM, CPU/memory/disk, Docker/Compose, pre-existing networks; tool checksum verification | [00-environment.txt](00-environment.txt), [00-tool-verification.txt](00-tool-verification.txt) |
| E1 | Tests pass; Compose build/status/logs; both endpoints; counter 1, 2, restart, 1 | [01-compose.txt](01-compose.txt) |
| E1b | Mac requests through the SSH tunnel return HTTP 200; request path documented | [01-host-access.txt](01-host-access.txt) |
| E2 | One-node cluster, same image import, two Ready replicas, successful Service requests | [02-cluster.txt](02-cluster.txt), [baseline Pods](02-baseline-pods.json), [baseline EndpointSlices](02-baseline-endpointslices.json) |
| E3 | One application Pod deleted and a new Pod replaces it; returns to two Ready replicas | [03-pod-replacement.txt](03-pod-replacement.txt), [before](03-before-delete-pods.json), [after](03-after-replacement-pods.json) |
| E4 | Selector mismatch keeps Pods healthy but gives zero ready endpoints and a failed client request; correcting it restores access | [04-selector-failure.txt](04-selector-failure.txt), [failure Pods](04-selector-failure-pods.json), [failure endpoints](04-selector-failure-endpointslices.json), [recovery endpoints](04-selector-recovery-endpointslices.json) |
| E5 | One replica remains Running with no restart but becomes NotReady; HTTP 503 at /health; only the other backend receives sampled Service requests | [05-readiness.txt](05-readiness.txt), [failure Pods](05-readiness-failure-pods.json), [failure endpoints](05-readiness-failure-endpointslices.json) |
| E6 | Marker removed, same Pods/container IDs remain, two Ready endpoints restored | [recovery Pods](05-readiness-recovery-pods.json), [recovery endpoints](05-readiness-recovery-endpointslices.json), [verification-summary.json](verification-summary.json) |
| E7 | Final service health, matching image, resource use, and removal of readiness markers | [06-final-verification.txt](06-final-verification.txt) |

## Screenshots

[Open the 11 terminal screenshots and matching text](screenshots/README.md). These were captured while rerunning the real commands in macOS Terminal, with Linux execution over SSH to Oracle. The Mac-to-VM image shows a local Mac command.

## Notes

These tests cover one node. They do not test a complete VM failure or heavy traffic. The OpenStack part is a written plan. I used a remote Oracle VM for the experiments, as described in the README.
