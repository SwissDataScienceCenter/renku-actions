FROM alpine/k8s:1.24.16

# install dependencies
COPY requirements.txt /
RUN apk add python3 docker jq yq && \
    pip3 install -r /requirements.txt

COPY deploy-dev-renku.py entrypoint.sh /
ENTRYPOINT /entrypoint.sh
