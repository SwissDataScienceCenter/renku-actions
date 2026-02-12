FROM alpine/k8s:1.32.11

# install dependencies
COPY requirements.txt /
RUN apk add --no-cache python3 docker jq && \
    wget -O /usr/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64" && \
    chmod a+x /usr/bin/yq && \
    pip3 install -r /requirements.txt

COPY deploy-dev-renku.py entrypoint.sh /
ENTRYPOINT /entrypoint.sh
