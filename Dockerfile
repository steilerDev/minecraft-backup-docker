FROM debian:bullseye-slim
ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.utf8

# Applying fs patch for assets
ADD rootfs.tar.gz /

# Install stuff and remove caches
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install \
        --no-install-recommends \
        --fix-missing \
        --assume-yes \
            apt-utils vim curl dialog locales wget xxd lzma cron procps && \
    apt-get clean autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/{apt,dpkg,cache,log} /tmp/* /var/tmp/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ARG DOCKER_CLI_VERSION="20.10.9"
ENV DOCKER_DOWNLOAD_URL="https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_CLI_VERSION.tgz"
RUN mkdir -p /tmp/download \
    && curl -L $DOCKER_DOWNLOAD_URL | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/docker /usr/local/bin/ \
    && rm -rf /tmp/download

WORKDIR /opt/mc-backup
VOLUME ["/world", "/history", "/config"]

RUN chmod +x /opt/mc-backup/* && \
    ln -s /opt/mc-backup/status.sh /usr/local/bin/status && \
    ln -s /opt/mc-backup/restore.sh /usr/local/bin/restore && \
    ln -s /opt/mc-backup/backup.sh /usr/local/bin/backup

ENTRYPOINT ["./entrypoint.sh"]
