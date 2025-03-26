# :: Distroless
  FROM 11notes/distroless AS distroless

# :: Build / adguard
  FROM golang:1.24-alpine AS adguard
  ARG TARGETARCH
  ARG APP_VERSION
  ARG APP_ROOT

  USER root

  RUN set -ex; \
    mkdir -p ${APP_ROOT}/etc/ssl; \
    mkdir -p ${APP_ROOT}/opt/data;

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
    cd /go/AdGuardHome; \
    git apply --whitespace=fix cap.patch; \
    make \
      build-release \
      CHANNEL="release" \
      VERSION=${APP_VERSION} \
      ARCH=${TARGETARCH} \
      OS=linux \
      SIGN=0 \
      VERBOSE=2;

  RUN set -ex; \
    openssl req -x509 -newkey rsa:4096 -subj "/C=XX/ST=XX/L=XX/O=XX/OU=docker/CN=adguard" \
      -keyout "${APP_ROOT}/etc/ssl/default.key" \
      -out "${APP_ROOT}/etc/ssl/default.crt" \
      -days 3650 -nodes -sha256 &> /dev/null; \
    strip -v /go/AdGuardHome/dist/AdGuardHome_linux_${TARGETARCH}/AdGuardHome/AdGuardHome; \
    mv /go/AdGuardHome/dist/AdGuardHome_linux_${TARGETARCH}/AdGuardHome/AdGuardHome ${APP_ROOT}/opt;


# :: Build / dnslookup 
  FROM golang:1.24-alpine AS dnslookup 
  ARG APP_ROOT
  USER root

  RUN set -ex; \
    apk --update --no-cache add \
      git; \
    mkdir -p ${APP_ROOT}/opt; \
    git clone https://github.com/ameshkov/dnslookup.git; \
    cd /go/dnslookup; \
    go build -ldflags="-extldflags=-static";

  RUN set -ex; \
    cd /go/dnslookup; \
    ls -lah /go/dnslookup; \
    mv /go/dnslookup/dnslookup ${APP_ROOT}/opt;
  

# :: Build / distroless
  FROM alpine AS fs
  ARG APP_ROOT
  USER root

  # :: copy all the files needed
  COPY --from=distroless --chown=1000:1000 /distroless/ /rootfs
  COPY ./rootfs/ /rootfs
  COPY --from=adguard ${APP_ROOT}/ /rootfs${APP_ROOT}
  COPY --from=dnslookup ${APP_ROOT}/ /rootfs${APP_ROOT}

  RUN set -ex; \
    mkdir -p /rootfs${APP_ROOT}/run; \
    ln -s ${APP_ROOT}/opt/data /rootfs${APP_ROOT}/var; \
    chmod -R 0700 /rootfs${APP_ROOT};


# :: Header
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
    COPY --from=fs --chown=1000:1000 /rootfs/ /

# :: Volumes
  VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var"]

# :: Monitor
  HEALTHCHECK --interval=5s --timeout=2s CMD ["/adguard/opt/dnslookup", ".", "NS",  "127.0.0.1"]

# :: Start
  USER docker
  ENTRYPOINT ["/adguard/opt/AdGuardHome"]
  CMD ["-c", "/adguard/etc/AdGuardHome.yaml", "--pidfile", "/adguard/run/adguard.pid", "--no-check-update"]