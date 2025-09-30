FROM golang:1.17-bullseye


RUN apt-get update && apt-get install -y git curl apt-transport-https
RUN curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update && \
    apt-get install -y helm
RUN go install fybrik.io/crdoc@v0.5.2

WORKDIR /action

CMD crdoc --resources ${RESOURCES} --output ${OUTPUT}
