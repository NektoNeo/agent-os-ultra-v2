#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source .venv/bin/activate 2>/dev/null || true

echo "Python: $(python -V 2>/dev/null || echo 'not in venv')"
echo "[brew binaries]"
for cmd in tesseract ffmpeg pngpaste cliclick ngrok; do
  if command -v $cmd >/dev/null 2>&1; then
    echo "  - $cmd: OK ($(command -v $cmd))"
  else
    echo "  - $cmd: MISSING"
  fi
done

echo "[python packages]"
python - <<'PY'
import importlib.util as iu
mods={"playwright":"playwright","opencv-python":"cv2","pytesseract":"pytesseract",
      "anthropic":"anthropic","openai":"openai","chromadb":"chromadb"}
for pipname,mod in mods.items():
    print(f"  - {pipname:15} -> {'OK' if iu.find_spec(mod) else 'MISSING'}")
PY
