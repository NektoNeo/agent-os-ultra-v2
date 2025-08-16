#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - "$@" <<'PY'
import json, os, pathlib, sys
p = pathlib.Path("config.json")
data = json.loads(p.read_text(encoding="utf-8"))
root = pathlib.Path(os.getcwd())
data["workspace"] = "./workspace"
p.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
print("config.json patched: workspace -> ./workspace")
PY
