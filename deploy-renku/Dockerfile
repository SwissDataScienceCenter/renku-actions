FROM alpine/k8s:1.23.17

# install dependencies
COPY requirements.txt /
RUN apk add --no-cache python3 docker jq && \
    wget -O /usr/bin/yq "https://github.com/mikefarah/yq/releases/download/3.1.1/yq_linux_amd64" && \
    chmod a+x /usr/bin/yq && \
    pip3 install -r /requirements.txt

COPY deploy-dev-renku.py entrypoint.sh /
ENTRYPOINT /entrypoint.sh
