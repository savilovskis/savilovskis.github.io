#!/bin/bash
# Кухня Лиха — свой сервер-посредник (TURN) для сетевой игры.
# Запуск на чистом сервере Ubuntu/Debian:  curl -fsSL https://savilovskis.github.io/turn-setup.sh | sudo bash
set -e
if [ "$(id -u)" != "0" ]; then echo "Запустите через sudo"; exit 1; fi
echo "== Ставлю coturn =="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null
apt-get install -y coturn curl >/dev/null
IP=$(curl -4 -fsS https://api.ipify.org 2>/dev/null || curl -4 -fsS https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
if [ -f /etc/kuhnya-turn.pass ]; then PASS=$(cat /etc/kuhnya-turn.pass); else PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16); echo "$PASS" >/etc/kuhnya-turn.pass; chmod 600 /etc/kuhnya-turn.pass; fi
cat >/etc/turnserver.conf <<EOF
listening-port=3478
fingerprint
lt-cred-mech
user=kuhnya:${PASS}
realm=kuhnya
external-ip=${IP}
min-port=49160
max-port=49999
no-cli
no-tls
no-dtls
no-multicast-peers
no-loopback-peers
denied-peer-ip=10.0.0.0-10.255.255.255
denied-peer-ip=172.16.0.0-172.31.255.255
denied-peer-ip=192.168.0.0-192.168.255.255
user-quota=12
total-quota=24
EOF
[ -f /etc/default/coturn ] && sed -i 's/^#\?TURNSERVER_ENABLED=.*/TURNSERVER_ENABLED=1/' /etc/default/coturn
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q active; then ufw allow 3478/tcp; ufw allow 3478/udp; ufw allow 49160:49999/udp; fi
systemctl enable coturn >/dev/null 2>&1 || true
systemctl restart coturn
sleep 1
systemctl is-active --quiet coturn && OK="работает" || OK="НЕ запустился — пришлите вывод: journalctl -u coturn -n 30"
echo
echo "==============================================="
echo " Сервер-посредник: $OK"
echo " Впишите в игре («Свой TURN-сервер»):"
echo "   Адрес:  turn:${IP}:3478, turn:${IP}:3478?transport=tcp"
echo "   Логин:  kuhnya"
echo "   Пароль: ${PASS}"
echo " Если у хостинга есть файрвол в панели — откройте"
echo " порт 3478 (TCP и UDP) и 49160–49999 (UDP)."
echo "==============================================="
