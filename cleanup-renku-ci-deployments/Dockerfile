FROM alpine/k8s:1.21.2
RUN apk add --no-cache jq
COPY entrypoint.sh /
ENTRYPOINT sh /entrypoint.sh
