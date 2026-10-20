#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
begin_log 02-cluster.txt
run k3d version
run kubectl version --client
run k3d cluster create cs554-midterm --servers 1 --agents 0 --no-lb \
  --api-port 127.0.0.1:16443 --subnet 172.29.55.0/24 --servers-memory 3g \
  --k3s-arg '--disable=traefik,servicelb@server:0' \
  --k3s-arg '--cluster-cidr=10.54.0.0/16@server:0' \
  --k3s-arg '--service-cidr=10.55.0.0/16@server:0' \
  --kubeconfig-update-default=false --kubeconfig-switch-context=false --wait
k3d kubeconfig get cs554-midterm > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"
run kubectl get nodes -o wide
run kubectl version
run k3d image import cs554-midterm:1.0.0 --cluster cs554-midterm
run kubectl apply -f k8s/app.yaml
run k rollout status deployment/midterm-app --timeout=120s
run kubectl apply -f k8s/client.yaml
run k wait pod/evidence-client --for=condition=Ready --timeout=120s
wait_ready_endpoints 2
capture_phase 02-baseline
run client_get http://midterm-app/
run client_get http://midterm-app/health
run service_samples
run k get pods -l app=midterm-app -o 'custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image,IMAGE_ID:.status.containerStatuses[0].imageID,READY:.status.containerStatuses[0].ready'
run docker image inspect cs554-midterm:1.0.0 --format 'Compose image ID={{.Id}}'
