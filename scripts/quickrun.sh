#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PORT:-5173}"
HOST="${HOST:-127.0.0.1}"
PUBLIC_URL="${PUBLIC_URL:-https://core.neo.ngrok.app}"

export ROOT PORT HOST PUBLIC_URL

echo "[quickrun] HOST=${HOST} PORT=${PORT} PUBLIC_URL=${PUBLIC_URL}"

# 1) Запуск uvicorn, если не поднят
if ! lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "[quickrun] Starting uvicorn on ${HOST}:${PORT}"
  mkdir -p "$ROOT/workspace"
  PYBIN="${PYBIN:-$ROOT/.venv/bin/python}"
if [ ! -x "$PYBIN" ]; then PYBIN="$(command -v python3)"; fi
nohup "$PYBIN" -m uvicorn server:app --host "$HOST" --port "$PORT" --log-level warning \
  >"$ROOT/workspace/uvicorn.log" 2>&1 &
  UV_PID=$!
  echo "$UV_PID" > "$ROOT/workspace/uvicorn.pid"
fi

# 2) Ждём /health
for i in {1..100}; do
  if curl -fsS "http://${HOST}:${PORT}/health" >/dev/null 2>&1; then
    echo "[quickrun] /health is up"
    break
  fi
  sleep 0.1
  if [[ $i -eq 100 ]]; then echo "[quickrun] FAIL: /health timeout" >&2; exit 1; fi
done

# 3) Ждём /openapi.json
for i in {1..100}; do
  if curl -fsS "http://${HOST}:${PORT}/openapi.json" >/dev/null 2>&1; then
    echo "[quickrun] /openapi.json is up"
    break
  fi
  sleep 0.1
  if [[ $i -eq 100 ]]; then echo "[quickrun] FAIL: /openapi.json timeout" >&2; exit 1; fi
done

# 4) Собираем УБЕР-ПАК (30 ops) и пишем в openapi/pack и actions/pack
python3 - <<'PY'
import os, json, urllib.request
from pathlib import Path

ROOT = Path(os.environ["ROOT"])
HOST = os.environ.get("HOST","127.0.0.1")
PORT = os.environ.get("PORT","5173")
PUBLIC_URL = os.environ.get("PUBLIC_URL","https://core.neo.ngrok.app")

with urllib.request.urlopen(f"http://{HOST}:{PORT}/openapi.json", timeout=3) as r:
    spec = json.load(r)

allow = [  # ровно 30 операций
 ("get","/health"),
 ("get","/shortcuts"),
 ("post","/run_shortcut"),
 ("post","/open_app"),
 ("post","/activate_app"),
 ("post","/open_url"),
 ("post","/keystroke"),
 ("post","/keycode"),
 ("post","/applescript/run"),
 ("post","/jxa/run"),
 ("get","/clipboard/get"),
 ("post","/clipboard/set"),
 ("post","/screen/capture"),
 ("post","/fs/read"),
 ("post","/fs/write"),
 ("post","/fs/mkdir"),
 ("post","/fs/list"),
 ("post","/exec/start"),
 ("get","/exec/status"),
 ("get","/exec/logs"),
 ("post","/exec/stop"),
 ("post","/git/status"),
 ("post","/git/commit"),
 ("post","/git/pull"),
 ("post","/git/push"),
 ("post","/browser/scrape"),
 ("post","/browser/crawl"),
 ("post","/extract/tabular"),
 ("post","/vision/locate_text"),
 ("post","/vision/click_at"),
]

src = spec.get("paths", {})
paths = {}
miss = []
for m,p in allow:
    ent = src.get(p)
    if ent and m in ent:
        paths[p] = {m: ent[m]}
    else:
        miss.append(f"{m.upper()} {p}")
if miss:
    print("[quickrun] WARN missing endpoints:\n  " + "\n  ".join(miss))

pack = {
  "openapi": "3.1.0",
  "info": {"title": "Agent OS – core pack", "version": "3.1.0"},
  "servers": [{"url": PUBLIC_URL}],
  "paths": paths,
  "components": spec.get("components", {}),
  "security": spec.get("security", []),
}

for rel in ["openapi/pack/core.json", "actions/pack/core.json"]:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(pack, ensure_ascii=False, indent=2), encoding="utf-8")
    print("[quickrun] wrote", p, "ops=", len(paths), "server=", PUBLIC_URL)
PY

echo "[quickrun] Import URL → ${PUBLIC_URL}/openapi/pack/core.json"
