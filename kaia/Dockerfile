# Official Kaia Docker Image
# Uses pre-built binaries from kaiachain/kaia

FROM kaiachain/kaia:${KAIA_TAG:-v2.2.2}

# Install additional tools for snapshot management
RUN apt-get update && apt-get install -y --no-install-recommends \
    aria2 \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create data directory structure
RUN mkdir -p /var/kend/data /var/kend/logs && \
    chmod -R 755 /var/kend

# Copy custom entrypoint
COPY ./docker-entrypoint.sh /usr/local/bin/

# Copy custom kend.conf template
COPY ./kend.conf /klaytn-docker-pkg/conf/kend.conf

# Make scripts executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME ["/var/kend/data"]

EXPOSE 8551 8552 32323 61001 32323/udp

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["kend", "start"]
