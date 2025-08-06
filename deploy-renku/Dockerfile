FROM alpine/k8s:1.23.17

# install dependencies
COPY requirements.txt /
RUN apk add --no-cache python3 python3-dev docker jq gcc musl-dev linux-headers && \
    wget -O /usr/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64" && \
    chmod a+x /usr/bin/yq && \
    pip3 install -r /requirements.txt && \
    apk del python3-dev gcc musl-dev linux-headers

COPY deploy-dev-renku.py entrypoint.sh /
ENTRYPOINT /entrypoint.sh
