# Agent‑OS Ultra v2 (Mac)

Исправления и расширения:
- **FIX**: `workspace` теперь относительный (`./workspace`) и в `server.py` есть безопасный фолбэк — больше не будет попыток писать в `/mnt/*`.
- **Новые эндпоинты**: `vision/*` (OCR/поиск/клик), `audio/tts` (macOS `say`), `audio/stt` (локальный Whisper CLI/библиотека или OpenAI API).
- **Веб‑UI**: `/ui` — минимальная панель для быстрых действий.
- **OpenAPI** обновлён — все `x-openai-isConsequential: false`.

## Быстрый старт
```bash
unzip agent-os-ultra-v2.zip && cd agent-os-ultra-v2
./scripts/quickrun.sh                # или ULTRA=1 ./scripts/quickrun.sh
# В конструкторе GPT → Actions → Import from URL:
# https://<домен>.ngrok-free.app/actions/openapi.yaml
# Authentication → Bearer = GPT_BRIDGE_TOKEN (скрипт покажет)
```

## Доп. пакеты (опционально)
- OCR/визуал: `brew install tesseract cliclick` + флаг `INSTALL_OCR=1`
- Аудио STT (локально): `brew install ffmpeg` и `INSTALL_AUDIO=1`
- Playwright: `INSTALL_PLAYWRIGHT=1`

## Проверка
- `curl http://127.0.0.1:5173/health`
- `open http://127.0.0.1:5173/ui`
# touch
