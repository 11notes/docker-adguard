#!/bin/ash
  if [ -z "$1" ]; then

    if [ ! -f "${APP_ROOT}/ssl/cert.pem" ]; then
      openssl req -x509 -newkey rsa:4096 -subj "/C=XX/ST=XX/L=XX/O=XX/OU=XX/CN=XX" \
        -keyout "${APP_ROOT}/ssl/key.pem" \
        -out "${APP_ROOT}/ssl/cert.pem" \
        -days 3650 -nodes -sha256 &> /dev/null
    fi

    set -- "AdGuardHome" \
      -c /adguard/etc/AdGuardHome.yaml \
      -w /adguard/var \
      --pidfile /adguard/run/adguard.pid \
      --no-check-update
  fi

  exec "$@"