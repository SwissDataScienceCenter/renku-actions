FROM bitnami/kubectl:1.25-debian-11

USER root
# install dependencies
RUN apt-get update && apt-get install -y git python3 python3-pip wget && \
    wget -O /usr/bin/yq "https://github.com/mikefarah/yq/releases/download/3.1.1/yq_linux_amd64" && \
    chmod 0755 /usr/bin/yq && \
    pip3 install -U pip chartpress==2.1.0 && \
    wget -O /tmp/helm.tar.gz "https://get.helm.sh/helm-v3.5.2-linux-amd64.tar.gz" && \
    tar -xf /tmp/helm.tar.gz --strip-components=1 -C /usr/bin/ && \
    chmod 0755 /usr/bin/helm && \
    rm -rf /var/lib/apt/lists/*

COPY publish-chart.sh /
ENTRYPOINT [ "/publish-chart.sh" ]
