ARG APP_UID=1000
ARG APP_GID=1000

# :: Util
  FROM 11notes/util AS util

# :: Build / adguard
  FROM golang:1.24-alpine AS build
  ARG TARGETARCH
  ARG TARGETPLATFORM
  ARG TARGETVARIANT
  ARG APP_ROOT
  ARG APP_VERSION
  ENV CGO_ENABLED=0
  ENV BUILD_DIR=/go/AdGuardHome
  ENV BUILD_BIN=${BUILD_DIR}/dist/AdGuardHome_linux_${TARGETARCH}${TARGETVARIANT}/AdGuardHome/AdGuardHome

  USER root

  COPY --from=util /usr/local/bin/ /usr/local/bin

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
      upx;

  RUN set -ex; \
    git clone https://github.com/AdguardTeam/AdGuardHome.git -b v${APP_VERSION};

  COPY /build/adguard/go/ /go

  RUN set -ex; \
    cd ${BUILD_DIR}; \
    git apply --whitespace=fix cap.patch;

  RUN set -ex; \
    cd ${BUILD_DIR}; \
    eleven printenv; \
    make \
      OS=linux \
      ARCH=${TARGETARCH} \
      CHANNEL="release" \
      VERSION=${APP_VERSION} \
      SIGN=0 \
      VERBOSE=3 \
      build-release;

  RUN set -ex; \
    mkdir -p /distroless/usr/local/bin; \
    mkdir -p /distroless/${APP_ROOT}/opt; \
    eleven strip ${BUILD_BIN}; \
    cp ${BUILD_BIN} /distroless/usr/local/bin;

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
  FROM scratch

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
    COPY --from=distroless --chown=${APP_UID}:${APP_GID} / /
    COPY --from=distroless-fs --chown=${APP_UID}:${APP_GID} / /
    COPY --from=distroless-dnslookup --chown=${APP_UID}:${APP_GID} / /
    COPY --from=distroless-adguard --chown=${APP_UID}:${APP_GID} / /

# :: Volumes
  VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var"]

# :: Monitor
  HEALTHCHECK --interval=5s --timeout=2s CMD ["/usr/local/bin/dnslookup", ".", "NS",  "127.0.0.1"]

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/AdGuardHome"]
  CMD ["-c", "/adguard/etc/config.yaml", "--pidfile", "/adguard/run/adguard.pid", "--work-dir", "/adguard/var", "--no-check-update"]