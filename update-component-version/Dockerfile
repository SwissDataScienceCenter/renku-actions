FROM python:3.7-alpine3.10

# install dependencies
RUN apk add --no-cache git bash && \
    apk add --no-cache --virtual .build-deps gcc g++ make && \
    wget -O /usr/bin/yq "https://github.com/mikefarah/yq/releases/download/3.1.1/yq_linux_amd64" && \
    chmod a+x /usr/bin/yq && \
# requests 2.32.0 has a bug with not allowing docker+http protocol, see requests/issues/6707
    pip install -U pip chartpress==2.1.0 six==1.16.0 "requests<2.32.0" && \
    apk del .build-deps && \
    cd /usr/bin && \
    wget https://github.com/google/yamlfmt/releases/download/v0.10.0/yamlfmt_0.10.0_Linux_x86_64.tar.gz && \
    tar -xvf yamlfmt_0.10.0_Linux_x86_64.tar.gz && \
    rm yamlfmt_0.10.0_Linux_x86_64.tar.gz && \
    chmod 0755 yamlfmt

COPY update-upstream.sh /
ENTRYPOINT [ "/update-upstream.sh" ]
