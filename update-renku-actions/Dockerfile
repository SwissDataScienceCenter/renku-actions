FROM alpine:3.15

RUN apk add --no-cache yq
COPY entrypoint.sh /
ENTRYPOINT sh /entrypoint.sh
