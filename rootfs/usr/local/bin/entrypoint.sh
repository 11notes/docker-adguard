#!/bin/ash
  if [ -z "${1}" ]; then
    if [ ! -f "${APP_ROOT}/ssl/default.crt" ]; then
      elevenLogJSON debug "creating default SSL certificate"
      openssl req -x509 -newkey rsa:4096 -subj "/C=XX/ST=XX/L=XX/O=XX/OU=XX/CN=adguard" \
        -keyout "${APP_ROOT}/ssl/default.key" \
        -out "${APP_ROOT}/ssl/default.crt" \
        -days 3650 -nodes -sha256 &> /dev/null
    fi

    elevenLogJSON info "starting ${APP_NAME} (${APP_VERSION})"
    set -- "AdGuardHome" \
      -c /adguard/etc/AdGuardHome.yaml \
      -w /adguard/var \
      --pidfile /adguard/run/adguard.pid \
      --no-check-update
  fi

  exec "$@"