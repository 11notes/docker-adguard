# :: Builder
  FROM 11notes/node:stable as build
  ENV checkout=v0.107.43
  ENV NODE_OPTIONS=--openssl-legacy-provider

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
      yarn;
    
  RUN set -ex; \
    git clone https://github.com/AdguardTeam/AdGuardHome.git; \
    cd /AdGuardHome; \
    git checkout ${checkout};

  RUN set -ex; \
    cd /AdGuardHome; \
    make;

# :: Header
	FROM 11notes/alpine:stable
  ENV APP_ROOT=/adguard
  COPY --from=build /AdGuardHome/AdGuardHome /usr/local/bin

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