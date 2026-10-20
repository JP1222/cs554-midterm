# CS554 Midterm

Jiapeng Chen · Fall 2026

I ran the class Node.js service with Docker Compose and Kubernetes, then tested Pod replacement, a wrong Service selector, and readiness failure in one replica.

- [Report and deployment diagram](docs/report.md)
- [Experiment logs and results](evidence/index.md)
- [Terminal screenshots](evidence/native-terminal/README.md)

I included screenshots and logs following the instructor's October 19 clarification that a video is not required.

## Setup

I used one Oracle Ubuntu 24.04.3 VM with four ARM64 CPUs and about 24 GB RAM. Both environments run on that VM; my Mac connects over SSH. This is a remote cloud VM, rather than a VM hosted on my Mac. Kubernetes runs as a single-node K3s cluster through k3d, with two application Pods and a separate test client Pod.

My tool versions were Docker 29.1.2, Compose v5.0.0, Node.js 22.22.0, k3d v5.9.0, and K3s v1.35.5+k3s1.

The application is based on the [class starter](https://github.com/UAH-Computer-Science/cs454-Course-Exercises/tree/8c572c153086cc68773c0e5804ccc0104ca34b3e/cs454-midterm-starter). I added the deployment files, experiment scripts, and file-based readiness check. `GET /` returns the hostname and a process-local request count. Health checks do not increase that count. `GET /health` returns 200, or 503 when the readiness marker file exists in that container.

## Prerequisites

Use a Linux VM with Docker Engine, Docker Compose, Bash, curl, and Node.js 22 or newer already installed. Your user must be able to run Docker. No npm dependencies are needed. Run the commands below from the project directory.

```bash
bash scripts/00-install-tools.sh
export PATH="$PWD/.tools:$PATH"
export KUBECONFIG="$PWD/.runtime/kubeconfig"
npm test
```

The install script downloads k3d and kubectl for ARM64 or AMD64 Linux and checks their published checksums. It needs access to GitHub and `dl.k8s.io`; building images also needs Docker Hub. On AMD64, build the image on that machine rather than copying my ARM64 image. The `.tools/` and `.runtime/` folders are created locally when running the scripts.

## Docker Compose

```bash
docker compose up --build -d --wait
docker compose ps
curl -i http://127.0.0.1:18080/
curl -i http://127.0.0.1:18080/health
docker compose logs --no-color
docker compose restart app
```

Compose builds `cs554-midterm:1.0.0` and runs it as the non-root `node` user. It sets `PORT`, `SERVICE_NAME`, `MESSAGE`, and `READINESS_BLOCK_FILE` through environment variables. VM port `127.0.0.1:18080` maps to container port `8080`.

To access it from my Mac, I kept this SSH tunnel open in one terminal:

```bash
ssh -N -L 127.0.0.1:18080:127.0.0.1:18080 oracle
```

Then, in a second Mac terminal:

```bash
curl -i http://127.0.0.1:18080/
curl -i http://127.0.0.1:18080/health
```

`oracle` is my SSH alias; replace it with your VM's SSH destination when reproducing the setup. The path is Mac port 18080 → SSH → VM loopback port 18080 → container port 8080. The VM's private address is `10.0.0.110`. I did not open a public HTTP port. The [Mac output](evidence/01-host-access.txt) records the successful requests.

## Kubernetes

Build the Compose image first. With the environment variables from the prerequisites section still set, create the cluster once:

```bash
bash scripts/02-cluster.sh
kubectl -n cs554-midterm get deployment,pods,service -o wide
```

The script creates the cluster, imports the same image, and applies `k8s/app.yaml` and `k8s/client.yaml`. The first file contains the Namespace, Deployment, and Service; the second defines a separate client Pod. The API uses VM loopback port 16443. The script saves the kubeconfig in `.runtime/`.

The image import and deployment commands used by the script are:

```bash
k3d image import cs554-midterm:1.0.0 --cluster cs554-midterm
kubectl apply -f k8s/app.yaml
kubectl apply -f k8s/client.yaml
kubectl -n cs554-midterm rollout status deployment/midterm-app
```

The Service selects the two application Pods and forwards port 80 to port 8080. `imagePullPolicy: Never` uses the imported image. To send a request through the Service:

```bash
kubectl -n cs554-midterm exec evidence-client -- node -e \
  'fetch("http://midterm-app/").then(async r=>console.log(r.status,await r.text()))'
```

An optional access method from the VM is `kubectl -n cs554-midterm port-forward service/midterm-app 18081:80`, followed by `curl http://127.0.0.1:18081/` in another terminal. For the failure experiments, I used the client Pod so requests went through Service routing.

## Repeat the experiments

The scripts below save results under `evidence/`. Copy that folder elsewhere first if you want to keep the original run. The cluster script also writes baseline evidence.

```bash
bash scripts/01-compose.sh
bash scripts/03-pod-replacement.sh
bash scripts/04-selector-failure.sh
bash scripts/05-readiness.sh
```

The selector and readiness scripts restore their temporary changes. The [report](docs/report.md) explains the results. Its Pod names and counts refer to the original logs; the terminal screenshots show a later run of the same experiments.

## Cleanup

```bash
bash scripts/cleanup.sh
```

This removes the project's Compose deployment and k3d cluster, keeping the source and evidence files. Stop any SSH tunnel or port-forward session with Ctrl+C.

The setup uses VM ports 18080 and 16443, Docker subnets `172.29.54.0/24` and `172.29.55.0/24`, Pod subnet `10.54.0.0/16`, and Service subnet `10.55.0.0/16`. Check these for conflicts on another machine.
