#!/usr/bin/env bash
# E2E checks against pulse-api deployed on a gitops-poc cluster, e.g.
#   ./scripts/e2e.sh http://k3s-stg:30080   (from the self-hosted runner)
# The /hostname check expects a pod name, so it fails against a local
# `cargo run` - every other check works there too.
set -euo pipefail

BASE_URL="${1:?usage: $0 <base-url>}"
failures=0

pass() { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; failures=$((failures + 1)); }

expect_status() { # path, expected status
  local status
  status=$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL$1")
  [ "$status" = "$2" ] && pass "GET $1 -> $status" || fail "GET $1 -> $status (want $2)"
}

expect_body() { # path, expected body
  local body
  body=$(curl -fsS "$BASE_URL$1" || true)
  [ "$body" = "$2" ] && pass "GET $1 -> '$body'" || fail "GET $1 -> '$body' (want '$2')"
}

echo "Waiting for $BASE_URL/ready..."
for _ in $(seq 1 30); do
  curl -fsS -o /dev/null "$BASE_URL/ready" && break
  sleep 2
done

expect_status /live 200
expect_status /ready 200
expect_body / "Hello, World!"
expect_body /hello "Hello, World!"
expect_status /does-not-exist 404

# /hostname returns the serving pod's name. Hit it a few times to check
# it's really answered by pulse-api pods behind the Service, and show how
# requests spread across replicas.
pods=$(for _ in $(seq 1 20); do curl -fsS "$BASE_URL/hostname" || true; echo; done | grep -v '^$' | sort | uniq -c || true)
echo "$pods"
if echo "$pods" | grep -q 'pulse-api-'; then
  pass "GET /hostname served by $(echo "$pods" | wc -l) pod(s)"
else
  fail "GET /hostname didn't return a pulse-api pod name"
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed"
  exit 1
fi
echo "All checks passed"
