# Changelog

Breaking changes are listed first in each entry. Read this before you apply an update from Railway.

## 2.0.0-beta.28 (2026-11-23)

First release of this template.

* Khoj 2.0.0-beta.28, official image `ghcr.io/khoj-ai/khoj:2.0.0-beta.28@sha256:eb2e44669df44b51cb206b394dc0a00c782ac152dda02c97c9e3dac3d643dbb4`.
* Railway PostgreSQL (pgvector) for users, chats and embeddings. A volume at `/root/.khoj` holds uploads, logs and the search models.
* Caddy 2.11.9 front: basic-auth login (`KHOJ_ADMIN_EMAIL`, generated `KHOJ_ADMIN_PASSWORD`), a generated `KHOJ_CLIENT_TOKEN` for the Obsidian, Emacs and desktop clients, and an open `/healthz`.
* Sets `DJANGO_ALLOW_ASYNC_UNSAFE=true`: without it the first chat on a new database fails with a 500 (`SynchronousOnlyOperation` in Khoj's default-model lookup).
* Migrations run under a Postgres advisory lock. The start script exits non-zero if Khoj or Caddy stops, and stops with a clear message on services with less than 1.2 GB of RAM.
