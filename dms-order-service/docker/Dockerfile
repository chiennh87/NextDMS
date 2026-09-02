# Multi-stage Dockerfile for dms-order-service
# Stage 1: Build the Go binary
FROM golang:1.27-alpine AS builder


# Set working directory
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Copy go module files first (better caching)
COPY go.mod ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary with optimizations
# -ldflags="-s -w" removes debug info (smaller binary)
# -trimpath removes file system paths from binary
# CGO_ENABLED=0 for static binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w" \
    -trimpath \
    -o /app/bin/dms-order-service \
    .

# Stage 2: Create minimal runtime image
#FROM alpine:3.18
FROM alpine:latest

# Install CA certificates and timezone data
RUN apk --no-cache add ca-certificates tzdata curl

# Create non-root user for security
RUN addgroup -S dms && adduser -S dms -G dms

# Set working directory
WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/bin/dms-order-service /app/dms-order-service

# Change ownership to non-root user
RUN chown -R dms:dms /app
USER dms

# Expose HTTP port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

# Set entry point
ENTRYPOINT ["/app/dms-order-service"]