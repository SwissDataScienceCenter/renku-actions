FROM alpine/k8s:1.35.0
RUN apk add --no-cache jq
COPY entrypoint.sh /
ENTRYPOINT sh /entrypoint.sh
