# Native Terminal screenshots

I reran the experiments in macOS Terminal and saved these window screenshots. The first ten show commands run on Oracle over SSH. The last one shows curl running on my Mac. Each screenshot also has a text copy of the output.

This run was on October 15, 2026, Central time (October 16 UTC). Some Pod names and counts differ from the earlier logs because I ran the experiments again with the same code and image.

| Screenshot | What it shows | Terminal text |
| --- | --- | --- |
| [01-compose.png](01-compose.png) | Compose status, both endpoints, logs, counts 1 and 2 | [text](01-compose.txt) |
| [02-compose-restart.png](02-compose-restart.png) | Counter returns to 1 after a restart | [text](02-compose-restart.txt) |
| [03-kubernetes.png](03-kubernetes.png) | Single node, two Ready application Pods, Service requests | [text](03-kubernetes.txt) |
| [04-pod-replacement.png](04-pod-replacement.png) | Pod deletion and its replacement | [text](04-pod-replacement.txt) |
| [05-selector-failure.png](05-selector-failure.png) | Wrong selector, healthy Pods, failed Service request | [text](05-selector-failure.txt) |
| [06-selector-recovery.png](06-selector-recovery.png) | Correct selector and successful request | [text](06-selector-recovery.txt) |
| [07-readiness-baseline.png](07-readiness-baseline.png) | Both Pods and Service endpoints ready | [text](07-readiness-baseline.txt) |
| [08-readiness-failure.png](08-readiness-failure.png) | One replica not ready, process still running, HTTP 503 | [text](08-readiness-failure.txt) |
| [09-readiness-recovery.png](09-readiness-recovery.png) | Same Pod UIDs, no restarts, two ready endpoints again | [text](09-readiness-recovery.txt) |
| [10-tests.png](10-tests.png) | Node.js version and two passing application tests | [text](10-tests.txt) |
| [11-mac-to-vm.png](11-mac-to-vm.png) | Mac curl through an SSH tunnel to the VM | [text](11-mac-to-vm.txt) |

For the Mac capture, local port 18082 forwards over SSH to VM loopback port 18080, then Docker forwards to container port 8080. The temporary tunnel was closed after capturing. The selector and readiness changes were restored.

In the output, `client_get` sends a request from the client Pod, and `wait_ready_endpoints` waits for the expected number of ready backends. Both helpers are in [scripts/common.sh](../../scripts/common.sh).
