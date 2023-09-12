# :: Builder
  FROM node:16.20.2-alpine as build
  ENV checkout=v0.107.38

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
      yarn; \
    git clone https://github.com/AdguardTeam/AdGuardHome.git; \
    cd /AdGuardHome; \
    git checkout ${checkout}; \
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
	VOLUME ["${APP_ROOT}"]

# :: Start
	USER docker
	ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]