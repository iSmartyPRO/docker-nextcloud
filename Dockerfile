FROM nextcloud:latest

# SMB for files_external + LibreDWG for DWG/DXF previews.
# Persist in the image so container recreate does not drop the tools.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        smbclient \
        libsmbclient-dev \
        librsvg2-bin \
        ${PHPIZE_DEPS}; \
    if apt-cache show libredwg-utils >/dev/null 2>&1; then \
        apt-get install -y --no-install-recommends libredwg-utils; \
    elif apt-cache show libredwg-tools >/dev/null 2>&1; then \
        apt-get install -y --no-install-recommends libredwg-tools; \
    else \
        apt-get install -y --no-install-recommends \
            build-essential \
            autoconf \
            automake \
            libtool \
            pkg-config \
            wget \
            ca-certificates; \
        wget -qO /tmp/libredwg.tar.gz \
            https://ftp.gnu.org/gnu/libredwg/libredwg-0.13.3.tar.gz; \
        mkdir -p /tmp/libredwg; \
        tar -xzf /tmp/libredwg.tar.gz -C /tmp/libredwg --strip-components=1; \
        cd /tmp/libredwg; \
        ./configure --prefix=/usr --disable-python --disable-bindings; \
        make -j"$(nproc)"; \
        make install; \
        ldconfig; \
        cd /; \
        rm -rf /tmp/libredwg /tmp/libredwg.tar.gz; \
        apt-get purge -y --auto-remove \
            build-essential autoconf automake libtool pkg-config wget; \
    fi; \
    pecl install smbclient; \
    docker-php-ext-enable smbclient; \
    apt-get purge -y --auto-remove ${PHPIZE_DEPS}; \
    rm -rf /var/lib/apt/lists/*
