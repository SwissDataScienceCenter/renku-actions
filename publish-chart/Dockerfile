FROM docker:24.0.6-git

# install dependencies
RUN apk add python3 py-pip py3-ruamel.yaml && \
    wget -O /usr/bin/yq "https://github.com/mikefarah/yq/releases/download/3.1.1/yq_linux_amd64" && \
    chmod 0755 /usr/bin/yq && \
    pip3 install -U pip chartpress==2.1.0 && \
    wget -O /tmp/helm.tar.gz "https://get.helm.sh/helm-v3.14.2-linux-amd64.tar.gz" && \
    tar -xf /tmp/helm.tar.gz --strip-components=1 -C /usr/bin/ && \
    chmod 0755 /usr/bin/helm

COPY publish-chart.sh /
ENTRYPOINT [ "/publish-chart.sh" ]
