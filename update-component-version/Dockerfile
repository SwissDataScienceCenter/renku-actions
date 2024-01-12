FROM python:3.9-alpine3.18

# install dependencies
RUN apk add --no-cache git bash yq && \
    pip install -U pip \
    chartpress==2.1.0 \
    'ruamel.yaml<0.17.10' \
    'ruamel.yaml.clib<0.2.4'

COPY update-upstream.sh /
ENTRYPOINT [ "/update-upstream.sh" ]
