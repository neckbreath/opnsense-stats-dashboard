FROM golang:1.21-alpine AS builder

WORKDIR /app
# Copy module file and sources, then resolve deps (generates go.sum)
COPY go.mod ./
COPY *.go ./
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -o event-collector .

FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/

COPY --from=builder /app/event-collector .

# Create log directory
RUN mkdir -p /var/log/event-collector

# Set timezone to Australia/Sydney
ENV TZ=Australia/Sydney

EXPOSE 8088

CMD ["./event-collector"]
