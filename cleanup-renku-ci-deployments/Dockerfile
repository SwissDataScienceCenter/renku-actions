FROM alpine/k8s:1.37.1
RUN apk add --no-cache jq
COPY entrypoint.sh /
ENTRYPOINT sh /entrypoint.sh
