# :: Builder
  FROM 11notes/node:stable as build
  ENV APP_ROOT=/AdGuardHome
  ENV APP_VERSION=v0.107.43
  ENV APP_ARCH="amd64"
  ENV APP_OS="linux"

  USER root

  RUN set -ex; \
    apk add --no-cache \
      go \
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
    git clone https://github.com/AdguardTeam/AdGuardHome.git; \
    cd ${APP_ROOT}; \
    git checkout ${APP_VERSION};

  # fix security
  RUN set -ex; \    
    # CVE-2023-49295⁠
    sed -i 's#github.com/quic-go/quic-go .*$#github.com/quic-go/quic-go v0.40.1#g' ${APP_ROOT}/go.mod; \ 
    # CVE-2023-48795
    sed -i 's#golang.org/x/crypto .*$#golang.org/x/crypto v0.17.0#g' ${APP_ROOT}/go.mod; \
    cd ${APP_ROOT}; \
    go mod tidy;

  RUN set -ex; \
    cd ${APP_ROOT}; \
    make \
      build-release \
      NODE_OPTIONS="--openssl-legacy-provider" \
      ARCH=${APP_ARCH} \
      OS=${APP_OS} \
      CHANNEL="release" \
      VERSION=${APP_VERSION} \
      SIGN=0 \
      VERBOSE=0; \
    mv /AdGuardHome/dist/AdGuardHome_${APP_OS}_${APP_ARCH}/AdGuardHome/AdGuardHome /usr/local/bin;

# :: Header
	FROM 11notes/alpine:stable
  ENV APP_ROOT=/adguard
  COPY --from=build /usr/local/bin/AdGuardHome /usr/local/bin

# :: Run
	USER root

	# :: prepare image
		RUN set -ex; \
			mkdir -p ${APP_ROOT}; \
      mkdir -p ${APP_ROOT}/etc; \
      mkdir -p ${APP_ROOT}/var; \
      mkdir -p ${APP_ROOT}/run; \
      mkdir -p ${APP_ROOT}/ssl;

  # :: install application
    RUN set -ex; \
      apk --no-cache add \
        openssl; \
      apk --no-cache upgrade;

	# :: copy root filesystem changes and set correct permissions
    COPY ./rootfs /
    RUN set -ex; \
      chmod +x -R /usr/local/bin; \
      chown -R 1000:1000 \
        ${APP_ROOT};

# :: Volumes
	VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var"]

# :: Monitor
  HEALTHCHECK CMD /usr/local/bin/healthcheck.sh || exit 1

# :: Start
	USER docker
	ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]