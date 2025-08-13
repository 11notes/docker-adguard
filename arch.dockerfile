# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_ROOT=/go/AdGuardHome \
      BUILD_SRC=AdguardTeam/AdGuardHome.git

# :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:dnslookup AS distroless-dnslookup

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: ADGUARD
  FROM 11notes/go:1.24 AS build
  ARG APP_VERSION \
      BUILD_ROOT \
      BUILD_SRC \
      TARGETARCH \
      TARGETPLATFORM \
      TARGETVARIANT
  ARG BUILD_BIN=${BUILD_ROOT}/dist/AdGuardHome_linux_${TARGETARCH}${TARGETVARIANT}/AdGuardHome/AdGuardHome

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
    eleven git clone ${BUILD_SRC} v${APP_VERSION};

  COPY /build/adguard/go/ /go

  RUN set -ex; \
    # fix caps patch
    cd ${BUILD_ROOT}; \
    git apply --whitespace=fix cap.patch;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
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