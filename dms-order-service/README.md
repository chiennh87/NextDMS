# DMS Order Service

Document Distribution Management System - Order Service cho hệ thống DMS FMCG.

## Tổng quan

- **Ngôn ngữ**: Go 1.22
- **Framework**: Gin-gonic
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Message Queue**: Apache Kafka
- **Metrics**: Prometheus + Grafana

## Kiến trúc

```
Clean Architecture / Hexagonal Architecture

├── cmd/api              # Entry point
├── internal/
│   ├── config/          # Configuration
│   ├── domain/           # Domain entities & interfaces
│   ├── usecase/         # Business logic
│   ├── infra/           # Adapters (Postgres, Redis, Kafka)
│   └── delivery/        # HTTP handlers & middleware
├── scripts/migrations/   # Database migrations
└── docker/              # Docker files
```

## API Endpoints

### Health Check
- `GET /healthz` - Liveness probe
- `GET /readyz` - Readiness probe
- `GET /health` - Combined health check

### Orders
- `POST /api/v1/orders` - Tạo đơn hàng mới

## Chạy local với Docker Compose

```bash
# Build và chạy tất cả services
docker-compose up -d

# Xem logs
docker-compose logs -f dms-order-service

# Stop services
docker-compose down
```

## Chạy local (Development)

```bash
# Cài đặt dependencies
go mod download

# Chạy migrations
psql $POSTGRES_DSN -f scripts/migrations/V1__initial_schema.sql
psql $POSTGRES_DSN -f scripts/migrations/V2__skus_table.sql
psql $POSTGRES_DSN -f scripts/migrations/V3__master_routes_table.sql
psql $POSTGRES_DSN -f scripts/migrations/V4__orders_table.sql

# Chạy service
go run cmd/api/main.go
```

## Môi trường

| Biến | Mô tả | Mặc định |
|-------|--------|-----------|
| PORT | HTTP port | 8080 |
| POSTGRES_DSN | PostgreSQL connection string | postgres://dms:dms_password@localhost:5432/dms?sslmode=disable |
| REDIS_ADDR | Redis address | localhost:6379 |
| KAFKA_BROKERS | Kafka brokers (comma-separated) | localhost:9092 |
| KAFKA_TOPIC | Kafka topic cho orders | dms.orders.v1 |
| ORDER_TIMEOUT_SEC | Timeout cho order operations | 5 |
| RATE_LIMIT_PER_MINUTE | Rate limit per salesman | 30 |

## Rate Limiting

Mặc định: 30 requests/phút/salesman

Header responses:
- `X-RateLimit-Limit` - Giới hạn tối đa
- `X-RateLimit-Remaining` - Số request còn lại
- `Retry-After` - Số giây phải chờ (khi bị 429)

## Metrics

Prometheus metrics endpoint: `GET /metrics`

Metrics chính:
- `dms_http_requests_total` - Total HTTP requests
- `dms_http_request_duration_seconds` - Request duration
- `dms_orders_created_total` - Total orders created
- `dms_order_value_dollars` - Order value distribution
- `dms_cache_hits_total` - Cache hits
- `dms_kafka_messages_sent_total` - Kafka messages sent

## Testing

```bash
# Chạy tất cả tests
go test ./...

# Chạy tests với coverage
go test -cover ./...

# Chạy tests với verbose
go test -v ./...
```

## Database Schema

### Tables
1. `outlets` - Điểm bán (100,000+ records)
2. `skus` - Sản phẩm
3. `master_routes` - Tuyến MCP
4. `orders` - Đơn hàng
5. `order_items` - Chi tiết đơn hàng

### Indexes
- Partial indexes cho `is_active = TRUE`
- GIST index cho GPS coordinates
- GIN index cho JSONB route_stops
- Composite indexes cho common queries

## Performance

- Target: 2,000-3,000 orders/giờ peak (8h-10h)
- Latency: 50-200ms (cache hit), 200-500ms (DB write)
- Concurrency: 100+ concurrent requests

## License

Proprietary - Internal use only