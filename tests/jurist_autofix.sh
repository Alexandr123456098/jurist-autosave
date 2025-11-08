#!/bin/bash
# --- Jurist auto-fix for STT (Whisper) ---
LOG="/var/log/jurist-autofix.log"
CHECK_LOG="/var/log/jurist-stt-check.log"

echo "[$(date '+%F %T')] 🩺 AutoFix start" >> "$LOG"

# 1. Проверяем последние 5 строк лога STT
if ! tail -n 5 "$CHECK_LOG" | grep -q "❌ STT FAIL"; then
  echo "[$(date '+%F %T')] ✅ No STT problem detected" >> "$LOG"
  exit 0
fi

echo "[$(date '+%F %T')] ⚠️ STT FAIL detected — restarting jurist.service" >> "$LOG"

# 2. Перезапуск jurist.service
systemctl restart jurist.service
sleep 8

# 3. Повторная проверка
bash /root/projects/jurist/tests/test_stt.sh
RESULT=$(tail -n 5 "$CHECK_LOG" | grep -E "✅|❌" | tail -n 1)

if echo "$RESULT" | grep -q "✅"; then
  echo "[$(date '+%F %T')] ✅ Whisper restored — $RESULT" >> "$LOG"
else
  echo "[$(date '+%F %T')] ❌ Still failing — switching to backup model" >> "$LOG"

  # 4. Попробуем использовать запасную модель
  sed -i 's/model=whisper-1/model=gpt-4o-mini-transcribe/g' /root/projects/jurist/tests/test_stt.sh
  bash /root/projects/jurist/tests/test_stt.sh
  RESULT2=$(tail -n 5 "$CHECK_LOG" | grep -E "✅|❌" | tail -n 1)

  if echo "$RESULT2" | grep -q "✅"; then
    echo "[$(date '+%F %T')] ✅ Whisper replaced with backup — OK" >> "$LOG"
  else
    echo "[$(date '+%F %T')] ❌ AutoFix failed — manual check required" >> "$LOG"
  fi
fi

echo "[$(date '+%F %T')] 🩺 AutoFix end" >> "$LOG"
exit 0
