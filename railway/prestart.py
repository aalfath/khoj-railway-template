"""Run before Khoj starts on Railway.

1. Wait for Postgres (a fresh project's private DNS can take a minute).
2. Apply Django migrations while holding a Postgres advisory lock, so two
   overlapping deploys never migrate at the same time.
3. Clear the scheduler-leader lock left by the previous container (Railway stops
   containers without a graceful shutdown, and a stale lock pauses automations
   for up to 12 hours).
4. After the first boot, keep the admin login and the OpenAI-compatible key and
   base URL in sync with the service variables. On the first boot Khoj itself
   creates the admin and the chat models from the same variables.
"""
import os
import sys
import time

import psycopg2

sys.path.insert(0, "/app/src")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "khoj.app.settings")

LOCK_ID = 4211013
params = dict(
    host=os.environ["POSTGRES_HOST"],
    port=os.environ.get("POSTGRES_PORT", "5432"),
    user=os.environ.get("POSTGRES_USER", "postgres"),
    password=os.environ["POSTGRES_PASSWORD"],
    dbname=os.environ.get("POSTGRES_DB", "khoj"),
    connect_timeout=5,
)


def log(msg):
    print(f"railway-prestart: {msg}", flush=True)


deadline = time.time() + 300
while True:
    try:
        conn = psycopg2.connect(**params)
        break
    except Exception as e:  # noqa: BLE001
        if time.time() > deadline:
            log(f"Postgres not reachable after 5 minutes: {e}")
            sys.exit(1)
        log("waiting for Postgres ...")
        time.sleep(3)
conn.autocommit = True
cur = conn.cursor()

deadline = time.time() + 600
while True:
    cur.execute("SELECT pg_try_advisory_lock(%s)", (LOCK_ID,))
    if cur.fetchone()[0]:
        break
    if time.time() > deadline:
        log("another deploy held the migration lock for 10 minutes; giving up")
        sys.exit(1)
    log("another deploy is migrating; waiting ...")
    time.sleep(3)

import django  # noqa: E402

django.setup()
from django.core.management import call_command  # noqa: E402

log("applying migrations")
call_command("migrate", "--noinput", verbosity=0)

from khoj.database.models import AiModelApi, KhojUser, ProcessLock  # noqa: E402

ProcessLock.objects.filter(name=ProcessLock.Operation.SCHEDULE_LEADER).delete()

email = os.environ["KHOJ_ADMIN_EMAIL"].strip()
password = os.environ["KHOJ_ADMIN_PASSWORD"]
first_boot = not KhojUser.objects.filter(is_staff=True).exists()
if first_boot:
    log("first boot: Khoj will create the admin and chat models")
else:
    user = KhojUser.objects.filter(username=email).first() or KhojUser.objects.filter(email=email).first()
    if user is None:
        KhojUser.objects.create_superuser(email=email, username=email, password=password)
        log("created admin user for the new KHOJ_ADMIN_EMAIL")
    elif not (user.is_staff and user.is_superuser and user.check_password(password)):
        user.is_staff = True
        user.is_superuser = True
        user.set_password(password)
        user.save()
        log("admin login updated from the service variables")

    key = os.environ.get("OPENAI_API_KEY", "").strip()
    base = os.environ.get("OPENAI_BASE_URL", "").strip() or None
    if key or base:
        n = 0
        for api in AiModelApi.objects.filter(name__in=["OpenAI", "Ollama"]):
            new_key = key or api.api_key
            if api.api_key != new_key or api.api_base_url != base:
                api.api_key = new_key
                api.api_base_url = base
                api.save()
                n += 1
        if n:
            log("OpenAI-compatible key/base URL updated from the service variables")

cur.execute("SELECT pg_advisory_unlock(%s)", (LOCK_ID,))
conn.close()
log("done")
