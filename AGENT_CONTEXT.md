# DMS Order Service - Agent Context

## Giới thiệu
Dự án DMS (Distribution Management System) cho doanh nghiệp FMCG lớn tại Việt Nam.
- Quy mô: 100,000+ điểm bán, 1,000+ Salesman
- Concurrency cao: Peak hours 8h-10h sáng
- Target: 2,000-3,000 orders/giờ peak

## Tech Stack
- Backend: Go 1.22, Clean Architecture / Hexagonal Architecture
- Database: PostgreSQL 15 (PostGIS extension)
- Cache: Redis 7
- Message Queue: Apache Kafka
- Metrics: Prometheus + Grafana
- HTTP Framework: Gin-gonic
- Validation: go-playground/validator/v10

## Cấu trúc dự án
```
dms-order-service/
├── cmd/api/                    # Entry point
├── internal/
│   ├── config/                 # Configuration từ env vars
│   ├── domain/order/           # Entities & Interfaces
│   │   └── entity.go          # Order, OrderItem, Repository interfaces
│   ├── usecase/order/          # Business logic
│   │   ├── order_usecase.go   # CreateOrder logic
│   │   ├── order_usecase_test.go
│   │   └── mocks_test.go       # Mock implementations
│   ├── infra/                  # Adapters
│   │   ├── cache/              # Redis cache adapter
│   │   ├── queue/              # Kafka adapter
│   │   └── repository/         # PostgreSQL adapter
│   └── delivery/http/
│       ├── handlers/           # Health check, Metrics
│       ├── middleware/          # Rate limiting
│       └── v1/                  # API handlers
├── scripts/migrations/          # Flyway-style migrations
├── docker/                     # Dockerfile, prometheus.yml
└── docker-compose.yml          # Full stack local dev
```

## Kiến trúc Clean Architecture
```
Delivery (HTTP Handler) → UseCase (Business Logic) → Domain (Interfaces) → Infra (Adapters)
```
## Domain Entities & Interfaces
Xem: internal/domain/order/entity.go

```go
// Entities: Order, OrderItem
// Interfaces: Repository, CacheRepository, MessageQueue
// Business Errors: ErrOutOfStock, ErrOutletInvalid, ErrEmptyItems
```

## API Endpoints
- POST /api/v1/orders - Tạo đơn hàng
- GET /healthz - Liveness probe
- GET /readyz - Readiness probe (DB + Redis)
- GET /metrics - Prometheus metrics

## Database Schema (PostgreSQL)
Tables: outlets (GPS), skus, master_routes (JSONB), orders, order_items
Indexes: Partial (is_active), GIST (GPS), GIN (JSONB), Composite

## Migrations
scripts/migrations/V1__initial_schema.sql - outlets
scripts/migrations/V2__skus_table.sql - skus
scripts/migrations/V3__master_routes_table.sql - master_routes
scripts/migrations/V4__orders_table.sql - orders + order_items

## Configuration
PORT=8080, POSTGRES_DSN, REDIS_ADDR, KAFKA_BROKERS, KAFKA_TOPIC, ORDER_TIMEOUT_SEC=5, RATE_LIMIT_PER_MINUTE=30

## Rate Limiting
Algorithm: Fixed Window Counter với Redis
Limit: 30 requests/phút/salesman
Headers: X-RateLimit-Limit, X-RateLimit-Remaining, Retry-After
Fail-open: Lỗi Redis → cho qua

## Performance Optimizations
- Context timeout 5s
- Redis cache cho stock check (200ms timeout)
- Kafka async publish (goroutine)
- Connection pools: Postgres MaxConns=50, Redis PoolSize=100
- Kafka batching: 16KB, Snappy compression

## Testing
go test ./... -v
Unit tests: TestCreateOrder_Success, TestCreateOrder_InsufficientStock, TestCreateOrder_EmptyItems, TestCreateOrder_RepositoryError, TestCreateOrder_CacheError, TestCreateOrder_MultipleItems, TestCreateOrder_Timeout

## Docker
docker-compose up -d (PostgreSQL, Redis, Kafka, Prometheus, Grafana, dms-order-service)

## Dependencies
github.com/gin-gonic/gin, github.com/go-playground/validator/v10, github.com/google/uuid, github.com/jackc/pgx/v5, github.com/prometheus/client_golang, github.com/redis/go-redis/v9, github.com/segmentio/kafka-go, github.com/stretchr/testify, go.uber.org/zap

## Lưu ý quan trọng
1. Order items dùng order.OrderItem từ domain package
2. Mocks trong mocks_test.go implements interfaces từ domain
3. Health check cần refactor để expose pgxpool.Pool
4. Metrics middleware cần wire vào router trong main.go

## Người dùng yêu cầu
- Vietnamese comments trong code
- Error handling chuẩn
- golangci-lint compliance
- Memory optimization cho high concurrency