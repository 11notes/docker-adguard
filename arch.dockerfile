# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

  # :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:dnslookup AS distroless-dnslookup
  FROM 11notes/util:bin AS util-bin

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: ADGUARD
  FROM golang:1.24-alpine AS build
  COPY --from=util-bin / /
  ARG APP_VERSION \
      BUILD_ROOT \
      BUILD_BIN \
      TARGETARCH \
      TARGETPLATFORM \
      TARGETVARIANT \
      BUILD_DIR=/go/AdGuardHome \
      CGO_ENABLED=0

  ENV BUILD_BIN=${BUILD_DIR}/dist/AdGuardHome_linux_${TARGETARCH}${TARGETVARIANT}/AdGuardHome/AdGuardHome

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
      yarn;

  RUN set -ex; \
    git clone https://github.com/AdguardTeam/AdGuardHome.git -b v${APP_VERSION};

  COPY /build/adguard/go/ /go

  RUN set -ex; \
    # fix caps patch
    cd ${BUILD_DIR}; \
    git apply --whitespace=fix cap.patch;

  RUN set -ex; \
    cd ${BUILD_DIR}; \
    make \
      OS=linux \
      ARCH=${TARGETARCH} \
      CHANNEL="release" \
      VERSION=${APP_VERSION} \
      SIGN=0 \
      VERBOSE=3 \
      build-release;

  RUN set -ex; \
    eleven distroless ${BUILD_BIN};

# :: FILE SYSTEM
  FROM alpine AS file-system
  ARG APP_ROOT
  USER root

  RUN set -ex; \
    mkdir -p /distroless${APP_ROOT}/etc; \
    mkdir -p /distroless${APP_ROOT}/var; \
    mkdir -p /distroless${APP_ROOT}/run;


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
      APP_NAME=${APP_NAME} \
      APP_VERSION=${APP_VERSION} \
      APP_ROOT=${APP_ROOT}

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=distroless-dnslookup / /
    COPY --from=build /distroless/ /
    COPY --from=file-system --chown=${APP_UID}:${APP_GID} /distroless/ /
    COPY --chown=${APP_UID}:${APP_GID} ./rootfs/ /

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var"]

# :: MONITORING
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/dnslookup", ".", "NS",  "127.0.0.1"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/AdGuardHome"]
  CMD ["-c", "/adguard/etc/config.yaml", "--pidfile", "/adguard/run/adguard.pid", "--work-dir", "/adguard/var", "--no-check-update"]