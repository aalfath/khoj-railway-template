# Deploy and Host Khoj on Railway

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

## Why Deploy Khoj on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Khoj on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
