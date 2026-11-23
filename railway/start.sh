#!/usr/bin/env bash
# Start Khoj on Railway: check settings, migrate under a lock, then run Khoj on
# 127.0.0.1:42110 behind Caddy (login + health check) on $PORT.
# Any exit of either process ends the container with a non-zero code, so
# Railway's ON_FAILURE restart policy brings it back.
set -euo pipefail

fail() { echo "railway-start: $*" >&2; exit 1; }

: "${PORT:=8080}"
export PORT
[ "$PORT" != "42110" ] || fail "PORT must not be 42110 (Khoj's internal port)."
for v in KHOJ_ADMIN_EMAIL KHOJ_ADMIN_PASSWORD KHOJ_CLIENT_TOKEN KHOJ_DJANGO_SECRET_KEY POSTGRES_HOST POSTGRES_PASSWORD; do
  [ -n "${!v:-}" ] || fail "$v is empty. Set it in the service's variables."
done
if [ -z "${OPENAI_API_KEY:-}${OPENAI_BASE_URL:-}${ANTHROPIC_API_KEY:-}${GEMINI_API_KEY:-}" ]; then
  fail "OPENAI_API_KEY is empty. Add your OpenAI (or OpenAI-compatible) API key to the Khoj service's variables."
fi

# Khoj loads torch and two local search models at boot and needs about 1.2 GB
# of RAM. Below that it would be OOM-killed mid-start, so say so plainly.
mem_max="$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo max)"
if [ "$mem_max" != "max" ] && [ "${KHOJ_SKIP_MEMORY_CHECK:-}" != "true" ] \
   && [ "$mem_max" -lt $((1200 * 1024 * 1024)) ]; then
  fail "this service has $((mem_max / 1024 / 1024)) MB of RAM, but Khoj needs about 1.2 GB (2 GB recommended). Raise the service's memory limit (Railway Hobby plan or higher) and redeploy."
fi
[ "${#KHOJ_ADMIN_PASSWORD}" -le 72 ] || fail "KHOJ_ADMIN_PASSWORD must be 72 characters or fewer."
case "$KHOJ_CLIENT_TOKEN" in *[[:space:]\"]*) fail "KHOJ_CLIENT_TOKEN must not contain spaces or quotes.";; esac

mkdir -p /root/.khoj/hf

# Basic-auth hash for Caddy, made fresh on each start from the current password.
KHOJ_AUTH_HASH="$(caddy hash-password --plaintext "$KHOJ_ADMIN_PASSWORD")"
export KHOJ_AUTH_HASH
caddy validate --config /railway/Caddyfile --adapter caddyfile >/dev/null 2>&1 \
  || { caddy validate --config /railway/Caddyfile --adapter caddyfile; fail "Caddyfile is invalid."; }

# Wait for Postgres, migrate under an advisory lock, keep the admin login and
# the LLM key in sync with the variables (see railway/prestart.py).
python3 /railway/prestart.py

caddy run --config /railway/Caddyfile --adapter caddyfile &
caddy_pid=$!

python3 /app/src/khoj/main.py --host 127.0.0.1 --port 42110 \
  --anonymous-mode --non-interactive --log-file /dev/null &
khoj_pid=$!

trap 'kill -TERM "$khoj_pid" "$caddy_pid" 2>/dev/null; wait; exit 143' TERM INT

set +e
wait -n "$khoj_pid" "$caddy_pid"
code=$?
set -e
if kill -0 "$khoj_pid" 2>/dev/null; then who="caddy"; else who="khoj"; fi
echo "railway-start: $who exited (code $code); stopping the container so Railway restarts it." >&2
kill -TERM "$khoj_pid" "$caddy_pid" 2>/dev/null || true
sleep 2
[ "$code" -ne 0 ] || code=1
exit "$code"
