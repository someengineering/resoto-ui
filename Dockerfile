FROM ubuntu:20.04 as build-env
ENV DEBIAN_FRONTEND=noninteractive
ARG TESTS
ARG SOURCE_COMMIT
ARG GODOT_DOWNLOAD_FOLDER=3.5/rc4/
ARG GODOT_VERSION=3.5
ARG GODOT_RELEASE=rc4
ARG GITHUB_REF
ARG GITHUB_REF_TYPE
ARG GITHUB_EVENT_NAME
ARG CRYPTO_EXPORT_TEMPLATES_DEBUG_URI=https://github.com/someengineering/godot-webassembly-export-templates/releases/download/v0.2.1/webassembly_debug.zip
ARG CRYPTO_EXPORT_TEMPLATES_RELEASE_URI=https://github.com/someengineering/godot-webassembly-export-templates/releases/download/v0.2.1/webassembly_release.zip
ARG RESOTO_UI_DO_API_TOKEN
ARG RESOTO_UI_SPACES_KEY
ARG RESOTO_UI_SPACES_SECRET
ARG RESOTO_UI_SPACES_NAME
ARG RESOTO_UI_SPACES_REGION
ARG RESOTO_UI_SPACES_PATH
ENV GITHUB_REF=$GITHUB_REF
ENV GITHUB_REF_TYPE=$GITHUB_REF_TYPE
ENV GITHUB_EVENT_NAME=$GITHUB_EVENT_NAME
ENV API_TOKEN=$RESOTO_UI_DO_API_TOKEN
ENV SPACES_KEY=$RESOTO_UI_SPACES_KEY
ENV SPACES_SECRET=$RESOTO_UI_SPACES_SECRET
ENV SPACES_NAME=$RESOTO_UI_SPACES_NAME
ENV SPACES_REGION=$RESOTO_UI_SPACES_REGION
ENV SPACES_PATH=$RESOTO_UI_SPACES_PATH
ENV UI_PATH=/usr/local/resoto/ui

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# Install Build dependencies
RUN apt-get update
RUN apt-get -y dist-upgrade
RUN apt-get -y install apt-utils
RUN apt-get -y install \
        curl \
        unzip \
        python3 \
        python3-pip \
        libmagic1

# Install Resoto UI uploader
COPY resoto-ui-upload /build/resoto-ui-upload
WORKDIR /build/resoto-ui-upload
RUN pip install .

# Download and install Godot
WORKDIR /build/godot
RUN mkdir -p /root/.local/share/godot/templates
RUN curl -L -o /tmp/godot.zip https://downloads.tuxfamily.org/godotengine/${GODOT_DOWNLOAD_FOLDER}/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux_headless.64.zip
RUN curl -L -o /tmp/godot.tpz https://downloads.tuxfamily.org/godotengine/${GODOT_DOWNLOAD_FOLDER}/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_export_templates.tpz
RUN curl -L -o /tmp/webassembly_debug.zip ${CRYPTO_EXPORT_TEMPLATES_DEBUG_URI}
RUN curl -L -o /tmp/webassembly_release.zip ${CRYPTO_EXPORT_TEMPLATES_RELEASE_URI}
RUN unzip /tmp/godot.zip -d /build/godot
RUN unzip /tmp/godot.tpz -d /root/.local/share/godot/templates
RUN mv /root/.local/share/godot/templates/templates /root/.local/share/godot/templates/${GODOT_VERSION}.${GODOT_RELEASE}
RUN mv -f /tmp/webassembly_debug.zip /root/.local/share/godot/templates/${GODOT_VERSION}.${GODOT_RELEASE}/webassembly_debug.zip
RUN mv -f /tmp/webassembly_release.zip /root/.local/share/godot/templates/${GODOT_VERSION}.${GODOT_RELEASE}/webassembly_release.zip

# Build resotoui
WORKDIR /usr/local/resoto/ui
COPY src /usr/src/ui
RUN /build/godot/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux_headless.64 --path /usr/src/ui --export HTML5 /usr/local/resoto/ui/index.html

# Upload resotoui
RUN if [ -n "$SPACES_NAME" ]; then resoto-ui-upload --verbose; fi

RUN echo "${SOURCE_COMMIT:-unknown}" > /usr/local/etc/git-commit.HEAD

# Setup main image
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG="en_US.UTF-8"
COPY --from=build-env /usr/local /usr/local
ENV PATH=/usr/local/python/bin:/usr/local/pypy/bin:/usr/local/db/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORKDIR /
RUN groupadd -g "${PGID:-0}" -o resoto \
    && useradd -g "${PGID:-0}" -u "${PUID:-0}" -o --create-home resoto \
    && apt-get update \
    && apt-get -y --no-install-recommends install apt-utils \
    && apt-get -y dist-upgrade \
    && apt-get -y --no-install-recommends install \
        iproute2 \
        libffi7 \
        openssl \
        procps \
        dateutils \
        curl \
        jq \
        cron \
        ca-certificates \
        openssh-client \
        locales \
        unzip \
    && echo 'LANG="en_US.UTF-8"' > /etc/default/locale \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && rm -f /bin/sh \
    && ln -s /bin/bash /bin/sh \
    && locale-gen \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/bin/bash"]
