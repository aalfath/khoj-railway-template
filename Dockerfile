# Khoj on Railway: the official Khoj image, pinned by version and digest, behind a
# small Caddy front that adds a login (Khoj's own single-user mode has none).
FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0 AS caddy

FROM ghcr.io/khoj-ai/khoj:2.0.0-beta.28@sha256:eb2e44669df44b51cb206b394dc0a00c782ac152dda02c97c9e3dac3d643dbb4

COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY railway/ /railway/
RUN chmod 755 /railway/start.sh && caddy version

# Keep torch, tokenizers and glibc from sizing themselves to the host's CPU count
# (Railway shows 32 CPUs inside a small service). Models and logs live on the volume.
# Khoj 2.0.0-beta.28 calls Django's sync ORM from its async chat path
# (get_default_chat_model), so the first chat on a new database fails with
# SynchronousOnlyOperation. Allow it (single-user setup; the call is a quick read).
# COLUMNS widens Rich tracebacks so they stay under Railway's log rate limit.
ENV DJANGO_ALLOW_ASYNC_UNSAFE=true \
    COLUMNS=160 \
    KHOJ_TELEMETRY_DISABLE=True \
    HF_HUB_DISABLE_TELEMETRY=1 \
    HF_HOME=/root/.khoj/hf \
    OMP_NUM_THREADS=2 \
    MKL_NUM_THREADS=2 \
    OPENBLAS_NUM_THREADS=2 \
    TOKENIZERS_PARALLELISM=false \
    MALLOC_ARENA_MAX=2 \
    PYTHONUNBUFFERED=1

WORKDIR /app
ENTRYPOINT ["/railway/start.sh"]
