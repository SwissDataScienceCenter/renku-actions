FROM docker:24.0.6-git

# install dependencies
# Note: Chartpress 0.7.0 is the latest version compatible until https://github.com/jupyterhub/chartpress/issues/118 is fixed
RUN apk add git python3 py-pip py3-ruamel.yaml && \
    wget -O /usr/bin/yq "https://github.com/mikefarah/yq/releases/download/3.1.1/yq_linux_amd64" && \
    chmod 0755 /usr/bin/yq && \
    pip3 install -U pip chartpress==2.1.0 && \
    wget -O /tmp/helm.tar.gz "https://get.helm.sh/helm-v3.5.2-linux-amd64.tar.gz" && \
    tar -xf /tmp/helm.tar.gz --strip-components=1 -C /usr/bin/ && \
    chmod 0755 /usr/bin/helm

COPY publish-images.sh /
ENTRYPOINT [ "/publish-images.sh" ]
