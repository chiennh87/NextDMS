# DMS Order Service API

RESTful API documentation for the DMS Order Service.

## Overview

The DMS Order Service handles order processing for an FMCG Distribution Management System supporting:
- 100,000+ outlets
- 1,000+ salesmen
- Real-time stock checking
- Asynchronous order publishing

## API Documentation

- **OpenAPI 3.0** specification: [`openapi.yaml`](./openapi.yaml)
- **Swagger 2.0** specification: [`swagger.json`](./swagger.json)
- **Generated docs**: Run `make swagger` to generate Go docs in [`docs.go`](./docs.go)

## Endpoints

### Health Checks
- `GET /healthz` - Liveness probe
- `GET /readyz` - Readiness probe (checks dependencies)
- `GET /metrics` - Prometheus metrics

### Orders
- `POST /api/v1/orders` - Create a new order
- `GET /api/v1/orders/{id}` - Get order by ID

## Generating Documentation

```bash
# Install swag CLI
go install github.com/swaggo/swag/cmd/swag@latest

# Generate documentation
swag init -g main.go --output ./docs --parseDependency --parseInternal

# View in browser
swag serve --port 8081 ./docs/swagger.json
```

## Using Swagger UI

After running the service, visit:
```
http://localhost:8080/swagger/index.html
```

## Authentication

All order endpoints require Bearer token authentication:
```
Authorization: Bearer <jwt_token>
```

The token should contain the salesman's ID and permissions.

## Rate Limiting

The API enforces rate limits per salesman:
- **Default**: 30 requests per minute per salesman
- **Burst**: 5 requests
- **Headers**: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After`

## Error Codes

| Code | Description |
|------|-------------|
| 400 | Invalid request format |
| 401 | Missing or invalid authentication |
| 403 | Insufficient permissions |
| 404 | Resource not found |
| 422 | Validation error (e.g., out of stock) |
| 429 | Rate limit exceeded |
| 500 | Internal server error |
| 503 | Service unavailable |