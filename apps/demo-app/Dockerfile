FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY src/ .
RUN go mod init github.com/example/secure-software-factory/demo-app && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o demo-app .

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /app/demo-app /demo-app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/demo-app"]
