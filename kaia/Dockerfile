ARG KAIA_TAG=v2.2.2
FROM kaiachain/kaia:${KAIA_TAG}

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget aria2 pigz tar jq \
  && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /usr/local/bin/kaia-docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/kaia-docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/kaia-docker-entrypoint.sh"]