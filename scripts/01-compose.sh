#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
begin_log 01-compose.txt
run uname -srmo
run node --version
run npm test
run docker compose config
run docker compose up --build -d --wait
run docker compose ps
run curl -fsS -i http://127.0.0.1:18080/health
printf '\nSuccessful health checks must not increase the root request counter.\n'
run curl -fsS http://127.0.0.1:18080/
printf '\n'
run curl -fsS http://127.0.0.1:18080/
printf '\n'
run docker compose logs --no-color --tail=30
run docker compose restart app
for attempt in {1..30}; do
  if curl -fsS http://127.0.0.1:18080/health >/dev/null; then break; fi
  sleep 1
done
printf '\nFirst root request after restart:\n'
run curl -fsS http://127.0.0.1:18080/
printf '\n'
run docker compose ps
run docker compose logs --no-color --tail=20
run docker image inspect cs554-midterm:1.0.0 --format 'Image={{.Id}} Architecture={{.Architecture}} User={{.Config.User}}'
run docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' cs554-midterm-app-1
