FROM alpine/k8s:1.32.11
RUN apk add --no-cache jq
COPY entrypoint.sh /
ENTRYPOINT sh /entrypoint.sh
