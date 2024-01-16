#!/bin/ash
  HEALTHCHECK_URL=${HEALTHCHECK_URL:-https://localhost:8443/ping}
  curl --insecure --max-time 3 -kILs --fail ${HEALTHCHECK_URL}