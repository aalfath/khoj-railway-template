[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/khoj-1?utm_medium=integration&utm_source=button&utm_campaign=khoj)

# Khoj on Railway

One-click [Khoj](https://github.com/khoj-ai/khoj) **2.0.0-beta.28** (`ghcr.io/khoj-ai/khoj:2.0.0-beta.28@sha256:eb2e44669df44b51cb206b394dc0a00c782ac152dda02c97c9e3dac3d643dbb4`) for [Railway](https://railway.com), with Railway's PostgreSQL (pgvector) and a login in front.

Khoj is an open-source AI second brain. You chat with an LLM about your own notes and documents and get answers that cite them. You can also build custom agents with their own instructions and schedule automations that research a topic and send you the results. Khoj runs in your browser and connects to Obsidian, Emacs and its desktop app.

## About Hosting Khoj

Khoj is a Python (FastAPI and Django) server that stores users, chats and vector embeddings of your documents in PostgreSQL with pgvector. It runs two small search models (embeddings and re-ranking) on the CPU, so it needs about 1.2 GB of RAM. The chat itself goes to an LLM you choose: OpenAI or any OpenAI-compatible API, with Anthropic and Gemini added from the admin panel. Hosting it means running the server and Postgres, keeping uploads and model files on persistent storage, and putting a login in front of it. Khoj's single-user mode has no login of its own. This template sets all of that up.

## Common Use Cases

* Ask questions about your own Markdown, PDF, Word and Org-mode notes and get answers that cite them
* A private ChatGPT-style assistant on your own server, using your own API key
* Scheduled research automations, plus custom agents with their own personality and knowledge

## Dependencies for Khoj Hosting

* An LLM API key: OpenAI, or any OpenAI-compatible provider (OpenRouter, Groq, DeepSeek, a vLLM or Ollama server) with its base URL
* PostgreSQL with pgvector (Railway's Postgres includes it)

### Deployment Dependencies

* Khoj source and releases: https://github.com/khoj-ai/khoj (this template runs release 2.0.0-beta.28)
* Self-hosting docs: https://docs.khoj.dev/get-started/setup
* Template source: https://github.com/aalfath/khoj-railway-template

### Implementation Details

**Services**

* **Khoj**: the official `ghcr.io/khoj-ai/khoj` image, pinned by version and digest, built from the template's GitHub repo. A small Caddy front on the public port adds the login and a `/healthz` health check. Khoj's data (uploads, logs and the downloaded search models) lives on a volume at `/root/.khoj`.
* **Postgres**: Railway's PostgreSQL with pgvector, on its own volume. It holds users, chats, agents, automations and the document embeddings.

**After deploy**

1. Open the Khoj service's **Variables** tab and copy `KHOJ_ADMIN_PASSWORD`. Sign in at your Railway URL with user `admin@example.com` (or the email you entered) and that password.
2. Start chatting, or upload documents from the attach button in the chat box or from **Settings**.
3. The admin panel is at `/server/admin`, behind the same login, and the same email and password sign you in there. Add more chat models, Anthropic or Gemini keys, or change the default model there.

**Variables**

* `OPENAI_API_KEY` (required): your OpenAI key, or the key for your OpenAI-compatible provider.
* `OPENAI_BASE_URL` (optional): leave empty for OpenAI. For another provider, use its OpenAI-compatible URL, for example `https://openrouter.ai/api/v1`.
* `KHOJ_DEFAULT_CHAT_MODEL` (optional): the default chat model, for example `gpt-4o-mini`.
* `KHOJ_ADMIN_EMAIL`, `KHOJ_ADMIN_PASSWORD`: your login. The password is generated. Change either one in Variables and redeploy.
* `KHOJ_CLIENT_TOKEN`: a generated token for the Obsidian, Emacs and desktop clients. Set the client's server URL to your Railway URL and paste this token as its API key.

**Resources:** Khoj needs about 1.2 GB of RAM (2 GB recommended), so use Railway's Hobby plan or higher. On a 0.5 GB service it stops with a clear message instead of crashing in a loop. Postgres fits in 0.5 GB. The image is about 3.7 GB, and the first build and boot take a few minutes.

**Left out on purpose:** SearxNG web search, the Terrarium code sandbox and Khoj's "computer" operator. The operator needs Docker access, which Railway doesn't allow. To turn on web search, add a `SERPER_DEV_API_KEY`, `EXA_API_KEY` or `FIRECRAWL_API_KEY` variable to the Khoj service. Email sign-in for more users needs `RESEND_API_KEY` and is off, because this template is a single-user setup behind one login.

**Updates:** the Khoj service builds from the template's GitHub repo. When a new Khoj version is pinned there, Railway shows you an update notice, and you choose when to apply it. Check `CHANGELOG.md` in the repo first.

## What's in this repo

* `Dockerfile`: `FROM` the pinned official Khoj image, plus the Caddy binary from a pinned `caddy:2.11.9-alpine` image.
* `railway/start.sh`: checks the variables and the RAM, runs `prestart.py`, then starts Khoj on `127.0.0.1:42110` and Caddy on `$PORT`. If either process exits, the container exits non-zero so Railway restarts it.
* `railway/prestart.py`: waits for Postgres, runs migrations under a Postgres advisory lock, clears a stale scheduler lock, and keeps the admin login and LLM key in sync with the variables after the first boot.
* `railway/Caddyfile`: basic auth for browsers, the client token for Khoj clients, and an open `/healthz`.

## Licence

Khoj is AGPL-3.0, (c) Khoj Inc. and contributors. The wrapper files in this repo are under the same licence. The source of the exact Khoj version deployed is at https://github.com/khoj-ai/khoj/tree/2.0.0-beta.28.
