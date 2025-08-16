#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# venv
python3 -m venv .venv >/dev/null 2>&1 || true
source .venv/bin/activate
python -m pip install -U pip setuptools wheel

# флаги
ALL=0; OCR=0; AUDIO=0; PLAY=0; VISION=0; SHEETS=0; VECTOR=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) ALL=1;;
    --ocr) OCR=1;;
    --audio) AUDIO=1;;
    --playwright) PLAY=1;;
    --vision) VISION=1;;
    --sheets) SHEETS=1;;
    --vector) VECTOR=1;;
  esac; shift
done
if [[ $ALL -eq 1 ]]; then OCR=1; AUDIO=1; PLAY=1; VISION=1; SHEETS=1; VECTOR=1; fi

brew_install() { command -v "$1" >/dev/null 2>&1 || brew install "$1"; }

# OCR/vision/клики
if [[ $OCR -eq 1 || $VISION -eq 1 ]]; then
  brew_install tesseract
  brew_install tesseract-lang || true
  brew_install pngpaste || true
  brew_install cliclick || true
  python -m pip install -U opencv-python pytesseract pillow
fi

# Аудио
if [[ $AUDIO -eq 1 ]]; then
  brew_install ffmpeg
  python -m pip install -U openai-whisper soundfile
fi

# Playwright
if [[ $PLAY -eq 1 ]]; then
  python -m pip install -U playwright
  python -m playwright install chromium
fi

# Google Sheets
if [[ $SHEETS -eq 1 ]]; then
  python -m pip install -U gspread google-auth
fi

# «лёгкая» векторная база (локально)
if [[ $VECTOR -eq 1 ]]; then
  python -m pip install -U chromadb
fi

echo "[addons] done."
