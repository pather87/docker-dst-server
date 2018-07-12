FROM debian:latest
LABEL maintainer="James Swineson <docker@public.swineson.me>"

ARG DEBIAN_FRONTEND=noninteractive
ARG STEAMCMD_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz

# install packages
RUN dpkg --add-architecture i386 \
 	&& apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ca-certificates lib32gcc1 lib32stdc++6 libcurl4-gnutls-dev:i386 wget tar supervisor \
    && apt-get autoremove -y \
 	&& apt-get clean -y \
 	&& rm -rf /var/lib/apt/lists/*

# install steamcmd
RUN mkdir -p /opt/steamcmd \
	&& wget "${STEAMCMD_URL}" -O /tmp/steamcmd.tar.gz \
	&& tar -xvzf /tmp/steamcmd.tar.gz -C /opt/steamcmd \
    && rm -rf /tmp/*

# install helper tools
COPY supervisor.conf /etc/supervisor/supervisor.conf
COPY entrypoint.sh /entrypoint.sh
COPY steamcmd /usr/local/bin/
COPY dontstarve_dedicated_server_nullrenderer /usr/local/bin/
COPY install_dst_server /opt/steamcmd_scripts/
RUN chmod +x /entrypoint.sh \
    && chmod +x /usr/local/bin/steamcmd \
    && chmod +x /usr/local/bin/dontstarve_dedicated_server_nullrenderer

# create data directory
# dst server seems to be ignoring `-persistent_storage_root` argument, let's workaround it too
RUN mkdir -p /data \
    && ln -s /data ${HOME}/.klei

# install Don't Starve Together server
RUN mkdir -p /opt/dst_server \
	&& steamcmd +runscript /opt/steamcmd_scripts/install_dst_server \
    && rm -rf /root/{Steam,.steam}

# install default config
COPY dst_default_config /opt/

EXPOSE 10999/udp 11000/udp
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["supervisord", "-c", "/etc/supervisor/supervisor.conf", "-n"]
HEALTHCHECK none
