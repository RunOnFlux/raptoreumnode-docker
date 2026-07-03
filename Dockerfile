FROM ubuntu:22.04
LABEL com.centurylinklabs.watchtower.enable="true"

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates wget curl jq pwgen supervisor cron tar gzip xz-utils bzip2 unzip procps \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /raptoreum/.raptoreumcore /var/log/supervisor

# Install Raptoreum Core.
# PIN the MAINNET release explicitly. Do NOT fetch "latest": the newest tag
# (2.0.4.01) ships TESTNET-only assets. 2.0.3.01-mainnet is the current mainnet
# build. Asset extracts flat to raptoreumd/raptoreum-cli/raptoreum-qt.
# NOTE the trailing '-' before .tar.gz in the asset name.
ARG RTM_VERSION=2.0.3.01-mainnet
RUN set -eux; \
    wget -qO /tmp/rtm.tgz \
      "https://github.com/Raptor3um/raptoreum/releases/download/${RTM_VERSION}/raptoreum-ubuntu22-${RTM_VERSION}-.tar.gz"; \
    mkdir -p /tmp/rtm; tar xzf /tmp/rtm.tgz -C /tmp/rtm; \
    ( cp /tmp/rtm/raptoreumd /tmp/rtm/raptoreum-cli /usr/local/bin/ 2>/dev/null \
      || cp /tmp/rtm/*/raptoreumd /tmp/rtm/*/raptoreum-cli /usr/local/bin/ ); \
    chmod +x /usr/local/bin/raptoreumd /usr/local/bin/raptoreum-cli; \
    rm -rf /tmp/rtm /tmp/rtm.tgz

COPY coin.env /usr/local/bin/coin.env
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY node_initialize.sh /usr/local/bin/node_initialize.sh
COPY mn-autoheal.sh /usr/local/bin/mn-autoheal.sh
COPY check-health.sh /usr/local/bin/check-health.sh
RUN chmod 755 /usr/local/bin/node_initialize.sh /usr/local/bin/mn-autoheal.sh \
              /usr/local/bin/check-health.sh /usr/local/bin/coin.env

VOLUME /raptoreum/.raptoreumcore
EXPOSE 10226
HEALTHCHECK --start-period=20m --interval=10m --retries=3 --timeout=15s CMD /usr/local/bin/check-health.sh
ENTRYPOINT ["/usr/bin/supervisord"]
