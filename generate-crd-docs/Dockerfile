FROM golang:1.17-bullseye


RUN apt-get update && apt-get install -y git curl apt-transport-https
RUN curl https://baltocdn.com/helm/signing.asc | apt-key add - && \
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list  && \
    apt-get update && \
    apt-get install -y helm
RUN go install fybrik.io/crdoc@v0.5.2

WORKDIR /action

CMD crdoc --resources ${RESOURCES} --output ${OUTPUT}
