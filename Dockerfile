FROM golang:1.21-alpine AS builder

RUN apk update && apk add curl gcc g++ libc-dev

ARG KAIGARA_VERSION=0.1.34
#ARG KAIGARA_VERSION=v1.0.35
# Install Kaigara
RUN curl -Lso /usr/bin/kaigara https://github.com/openware/kaigara/releases/download/${KAIGARA_VERSION}/kaigara \
  && chmod +x /usr/bin/kaigara

WORKDIR /build
ENV CGO_ENABLED=1 \
  GOOS=linux \
  GOARCH=amd64

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build ./cmd/rango

FROM alpine:3.18
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /build/rango ./
COPY --from=builder /usr/bin/kaigara /usr/bin/kaigara
RUN mkdir -p /app/config

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["./rango"]

