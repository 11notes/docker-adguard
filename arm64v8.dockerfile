# :: Util
  FROM alpine as util

  RUN set -ex; \
    apk add --no-cache \
      git; \
    git clone https://github.com/11notes/util.git;

# :: Build
  FROM 11notes/node:stable as build
  ENV BUILD_ROOT=/AdGuardHome
  ENV BUILD_VERSION=0.107.52
  ENV BUILD_ARCH="arm64"
  ENV BUILD_OS="linux"

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
    git clone https://github.com/AdguardTeam/AdGuardHome.git -b v${BUILD_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    make \
      build-release \
      NODE_OPTIONS="--openssl-legacy-provider" \
      ARCH=${BUILD_ARCH} \
      OS=${BUILD_OS} \
      CHANNEL="release" \
      VERSION=${APP_VERSION} \
      SIGN=0 \
      VERBOSE=0; \
    mv /AdGuardHome/dist/AdGuardHome_${BUILD_OS}_${BUILD_ARCH}/AdGuardHome/AdGuardHome /usr/local/bin;

# :: Header
	FROM --platform=linux/arm64 11notes/alpine:stable
  ENV APP_ROOT=/adguard
  ENV APP_NAME="adguard"
  ENV APP_VERSION=0.107.52
  COPY --from=util /util/linux/shell/elevenLogJSON /usr/local/bin
  COPY --from=build /usr/local/bin/AdGuardHome /usr/local/bin

# :: Run
	USER root

	# :: prepare image
		RUN set -ex; \
			mkdir -p ${APP_ROOT}; \
      mkdir -p ${APP_ROOT}/etc; \
      mkdir -p ${APP_ROOT}/var; \
      mkdir -p ${APP_ROOT}/ssl; \
      mkdir -p ${APP_ROOT}/run;

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
	VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var", "${APP_ROOT}/ssl"]

# :: Monitor
  HEALTHCHECK CMD /usr/local/bin/healthcheck.sh || exit 1

# :: Start
	USER docker
	ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]