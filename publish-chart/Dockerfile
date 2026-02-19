FROM docker:29.2.1-dind

# install dependencies
RUN apk add python3 py-pip py3-ruamel.yaml && \
    wget -O /usr/bin/yq "https://github.com/mikefarah/yq/releases/download/3.1.1/yq_linux_amd64" && \
    chmod 0755 /usr/bin/yq && \
    python3 -m venv /app/.venv && \
# requests 2.32.0 has a bug with not allowing docker+http protocol, see requests/issues/6707
    /app/.venv/bin/pip3 install pip chartpress==2.1.0 "requests<2.32.0" && \
    wget -O /tmp/helm.tar.gz "https://get.helm.sh/helm-v3.14.2-linux-amd64.tar.gz" && \
    tar -xf /tmp/helm.tar.gz --strip-components=1 -C /usr/bin/ && \
    chmod 0755 /usr/bin/helm

COPY publish-chart.sh /
ENTRYPOINT [ "/publish-chart.sh" ]
