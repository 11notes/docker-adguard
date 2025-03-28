# :: Build / adguard
  FROM golang:1.24-alpine AS build
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  ENV BUILD_DIR=/go/AdGuardHome
  ENV CGO_ENABLED=0

  USER root

  RUN set -ex; \
    apk --update --no-cache add \
      curl \
      wget \
      unzip \
      build-base \
      linux-headers \
      make \
      cmake \
      g++ \
      git \
      npm \
      gpg \
      zip \
      tar \
      yarn \
      openssl;

  RUN set -ex; \
    git clone https://github.com/AdguardTeam/AdGuardHome.git -b v${APP_VERSION};

  COPY /build/adguard/go/ /go

  RUN set -ex; \
    cd ${BUILD_DIR}; \
    git apply --whitespace=fix cap.patch;

  RUN set -ex; \
    cd ${BUILD_DIR}; \
    make \
      build-release \
      CHANNEL="release" \
      VERSION=${APP_VERSION} \
      ARCH=${TARGETARCH} \
      OS=linux \
      SIGN=0 \
      VERBOSE=2;

  RUN set -ex; \
    mkdir -p /distroless/usr/local/bin; \
    mkdir -p /distroless/${APP_ROOT}/etc/ssl; \
    mkdir -p /distroless/${APP_ROOT}/opt; \
    openssl req -x509 -newkey rsa:4096 -subj "/C=XX/ST=XX/L=XX/O=XX/OU=docker/CN=adguard" \
      -keyout "/distroless/${APP_ROOT}/etc/ssl/default.key" \
      -out "/distroless/${APP_ROOT}/etc/ssl/default.crt" \
      -days 3650 -nodes -sha256 &> /dev/null; \
    strip -v ${BUILD_DIR}/dist/AdGuardHome_linux_${TARGETARCH}/AdGuardHome/AdGuardHome; \
    cp ${BUILD_DIR}/dist/AdGuardHome_linux_${TARGETARCH}/AdGuardHome/AdGuardHome /distroless/usr/local/bin;

# :: Distroless / adguard
  FROM scratch AS distroless-adguard
  ARG APP_ROOT
  COPY --from=build /distroless/ /


# :: Build / file system
  FROM alpine AS fs
  ARG APP_ROOT
  USER root

  RUN set -ex; \
    mkdir -p ${APP_ROOT}/etc; \
    mkdir -p ${APP_ROOT}/var; \
    mkdir -p ${APP_ROOT}/run;

  COPY ./rootfs /

# :: Distroless / file system
  FROM scratch AS distroless-fs
  ARG APP_ROOT
  COPY --from=fs ${APP_ROOT} /${APP_ROOT}


# :: Header
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:dnslookup AS distroless-dnslookup
  FROM alpine

  # :: arguments
    ARG TARGETARCH
    ARG APP_IMAGE
    ARG APP_NAME
    ARG APP_VERSION
    ARG APP_ROOT
    ARG APP_UID
    ARG APP_GID

  # :: environment
    ENV APP_IMAGE=${APP_IMAGE}
    ENV APP_NAME=${APP_NAME}
    ENV APP_VERSION=${APP_VERSION}
    ENV APP_ROOT=${APP_ROOT}

  # :: multi-stage
    COPY --from=distroless --chown=1000:1000 / /
    COPY --from=distroless-fs --chown=1000:1000 / /
    COPY --from=distroless-dnslookup --chown=1000:1000 / /
    COPY --from=distroless-adguard --chown=1000:1000 / /

# :: Volumes
  VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var"]

# :: Monitor
  HEALTHCHECK --interval=5s --timeout=2s CMD ["dnslookup", ".", "NS",  "127.0.0.1"]

# :: Start
  USER 1000
  ENTRYPOINT ["AdGuardHome"]
  CMD ["-c", "/adguard/etc/config.yaml", "--pidfile", "/adguard/run/adguard.pid", "--work-dir", "/adguard/var", "--no-check-update"]