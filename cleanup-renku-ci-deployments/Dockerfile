FROM golang:1.24 AS build

WORKDIR /go/src/app
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN go vet -v
RUN CGO_ENABLED=0 go build -o /go/bin/app

FROM gcr.io/distroless/static-debian12
COPY --from=build /go/bin/app /
ENTRYPOINT ["/app"]
