FROM alpine:3.18

# install dependencies
RUN apk update && \
    apk add --no-cache git bash yq

COPY rollout-renku-deployment.sh /
RUN chmod +x /rollout-renku-deployment.sh
ENTRYPOINT [ "/rollout-renku-deployment.sh" ]
