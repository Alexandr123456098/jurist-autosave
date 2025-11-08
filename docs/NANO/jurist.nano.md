# Ассистент Юриста 1.5 PRO — NANO эталон

## Пути и состав
- Код бота: /root/main_assistant_yurist_v1.5.py
- Проект: /root/projects/jurist/
- .env: /root/projects/jurist/.env
- Юнит: /etc/systemd/system/jurist.service
- Drop-in: /etc/systemd/system/jurist.service.d/checkenv.conf, override.conf
- Логи: journalctl -u jurist.service -f -n 100
- Git (автосейв): /root/projects/jurist → git@github.com:Alexandr123456098/jurist-autosave.git

## systemd юнит (эталон)
/etc/systemd/system/jurist.service
---------------------------------
[Unit]
Description=Assistant Jurist Bot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/root
EnvironmentFile=/root/projects/jurist/.env
ExecStart=/usr/bin/python3 /root/main_assistant_yurist_v1.5.py
Restart=on-failure
RestartSec=5s
TimeoutStartSec=30s
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target

/etc/systemd/system/jurist.service.d/checkenv.conf
--------------------------------------------------
[Service]
ExecStartPre=/usr/local/bin/secret-export /root/projects/jurist/.env
ExecStartPre=/bin/sh -c 'test -s /root/projects/jurist/.env || { echo "ERROR: /root/projects/jurist/.env missing"; exit 1; }'
ExecStartPre=/bin/sh -c '. /root/projects/jurist/.env; test -n "$OPENAI_API_KEY" || { echo "ERROR: OPENAI_API_KEY is empty"; exit 1; }'

/etc/systemd/system/jurist.service.d/override.conf
--------------------------------------------------
[Service]
# NANO эталон — jurist.service

## Пути
СКРИПТ: /root/main_assistant_yurist_v1.5.py
UNIT:   /etc/systemd/system/jurist.service
ENV:    /root/projects/jurist/.env
ЛОГИ:   journalctl -u jurist.service -n 200 --no-pager

## .env (шаблон — сюда ВРУЧНУЮ вписываются реальные ключи)
TELEGRAM_BOT_TOKEN=__FILL__
OPENAI_API_KEY=__FILL__
ADMIN_ID=1079011202
DB_PATH=/root/projects/jurist/jurist.db
EDGE_VOICE=ru-RU-DmitryNeural
GMAIL_USER=__FILL__
GMAIL_PASS=__FILL__
GMAIL_IMAP=imap.gmail.com
PYTHONUNBUFFERED=1

## Проверка/запуск
systemctl daemon-reload
systemctl enable --now jurist.service
systemctl restart jurist.service
systemctl status jurist.service --no-pager
journalctl -u jurist.service -n 200 --no-pager
journalctl -u jurist.service -f -n 100

## Дениска / NANO
curl -u alex:FL21010808 -fsS http://127.0.0.1:8081/ping && echo
curl -u alex:FL21010808 -fsS http://127.0.0.1:8081/nano_index | jq -c '.projects|map({p:.project,c:(.items|length)})'

## Снапшот (git + STATE)
bash /root/bin/deniska-snapshot.sh

## Чёрный список
- Пустой OPENAI_API_KEY → петля рестартов. Заполняем ENV перед стартом.
- Реальные секреты храним ТОЛЬКО в /root/projects/jurist/.env (в гит не кладём).
- Неверный TELEGRAM_BOT_TOKEN → бот молчит.
