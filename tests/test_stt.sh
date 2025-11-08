#!/bin/bash
# --- Jurist STT self-check ---
LOG_FILE="/var/log/jurist-stt-check.log"
TMP_DIR="/root/projects/jurist/tests/tmp"
mkdir -p "$TMP_DIR"

echo "[$(date '+%F %T')] === STT SELF TEST START ===" >> "$LOG_FILE"

# 1. Проверяем ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "[$(date '+%F %T')] ERROR: ffmpeg not found" >> "$LOG_FILE"
  exit 1
fi

# 2. Проверяем наличие Whisper Python-модуля
if ! python3 - <<'EOF'
import importlib
importlib.import_module("openai")
EOF
then
  echo "[$(date '+%F %T')] ERROR: openai module missing" >> "$LOG_FILE"
  exit 1
fi

# 3. Создаём тестовый .ogg с помощью espeak-ng
echo "[$(date '+%F %T')] Generating test audio..." >> "$LOG_FILE"
TEST_FILE="$TMP_DIR/test.ogg"
espeak-ng -vru "Проверка связи" --stdout | ffmpeg -loglevel quiet -y -i - -ac 1 -ar 16000 "$TEST_FILE"

# 4. Отправляем в Whisper API через curl
source /root/projects/jurist/.env

RESP=$(curl -s -X POST "https://api.openai.com/v1/audio/transcriptions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F "model=whisper-1" \
  -F "file=@$TEST_FILE")

TRANS=$(echo "$RESP" | jq -r '.text // empty')

if [ -z "$TRANS" ]; then
  echo "[$(date '+%F %T')] ❌ STT FAIL — no text received" >> "$LOG_FILE"
  echo "$RESP" >> "$LOG_FILE"
  exit 1
else
  echo "[$(date '+%F %T')] ✅ STT OK — '$TRANS'" >> "$LOG_FILE"
fi

echo "[$(date '+%F %T')] === STT SELF TEST END ===" >> "$LOG_FILE"
exit 0
