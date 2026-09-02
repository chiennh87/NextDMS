# DMS Outlet Service - Enterprise FMCG Backend

Go microservice for outlet onboarding with enterprise features: Approval Workflow, Offline-First Sync, Multi-Country, Data Scoping.

## Architecture

```
dms-outlet-service/
├── cmd/
│   └── main.go              # Entry point + Gin router setup
├── internal/
│   ├── domain/              # Entities + DTOs
│   │   └── outlet.go
│   ├── repository/postgres/ # Data access layer
│   │   └── outlet_repository.go
│   ├── usecase/             # Business logic
│   │   └── outlet_usecase.go
│   └── delivery/http/handler/ # HTTP handlers
│       └── outlet_handler.go
├── scripts/
│   └── run_migrations.sql
├── go.mod
├── Makefile
└── README.md
```

## Enterprise Features

### 1. Approval Workflow
- States: `DRAFT` → `PENDING_APPROVAL` → `APPROVED` / `REJECTED`
- Endpoints: `PATCH /api/v1/outlets/:id/approve`, `PATCH /api/v1/outlets/:id/reject`
- Audit trail: `approved_by`, `approval_date`, `rejected_reason`

### 2. Offline-First Sync
- Endpoints: `POST /api/v1/outlets/sync`, `PATCH /api/v1/outlets/sync-status`, `GET /api/v1/outlets/pending-sync`
- Server-side: `tblSyncLog` table logs all sync attempts
- Client-side: Mobile app uses SQLite + connectivity_plus for queue management

### 3. Multi-Country Support
- All master data tables include `country_code` (VNM, LAO, CAM, MMR)
- All address tables (Province, District, Ward) filterable by country
- All queries support `country_code` filter

### 4. Data Scoping (RLS)
- Every outlet is scoped to `distributor_id` + `territory_id`
- All queries filter by scoping (mandatory)
- PostgreSQL RLS policy enforces `current_setting('app.current_distributor_id')`

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST   | /api/v1/outlets | Create new outlet (PENDING_APPROVAL) |
| GET    | /api/v1/outlets | List outlets (scoped) |
| GET    | /api/v1/outlets/:id | Get outlet by ID |
| POST   | /api/v1/outlets/check-duplicate | Check for duplicates |
| POST   | /api/v1/outlets/sync | **Sync from offline draft** |
| PATCH  | /api/v1/outlets/sync-status | Update sync status |
| GET    | /api/v1/outlets/pending-sync | Get pending sync outlets |
| PATCH  | /api/v1/outlets/:id/approve | **Approve outlet** |
| PATCH  | /api/v1/outlets/:id/reject | **Reject outlet** |
| GET    | /api/v1/value-set-values?country_code=VNM | Multi-country master data |
| GET    | /api/v1/provinces?country_code=VNM | Provinces by country |
| GET    | /api/v1/districts?province_code=HN | Districts by province |
| GET    | /api/v1/wards?district_code=001 | Wards by district |
| POST   | /api/v1/outlets/upload-photo | Upload photo (multipart) |
| GET    | /health | Health check |
| GET    | /metrics | Prometheus metrics |

## Setup

### Prerequisites
- Go 1.22+
- PostgreSQL 15+
- (Optional) Redis for rate limiting

### 1. Database Setup
```bash
# Create database
createdb -U postgres dms

# Run migrations
make migrate
```

### 2. Environment Variables
```bash
export DATABASE_URL="postgres://postgres:postgres@localhost:5432/dms?sslmode=disable"
export PORT="3001"
export SENTRY_DSN="<your-sentry-dsn>"  # optional
export ENV="development"
```

### 3. Build & Run
```bash
# Install dependencies
make mod

# Build
make build

# Run
make run

# Or with Docker
make docker-build
make docker-run
```

## API Examples

### Create Outlet
```bash
curl -X POST http://localhost:3001/api/v1/outlets \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{
    "code": "OL-001",
    "name": "Tạp hoá Bà Năm",
    "phone": "0901234567",
    "tax_code": "123456789",
    "province_code": "HN",
    "district_code": "001",
    "ward_code": "00001",
    "latitude": 21.028511,
    "longitude": 105.804817,
    "distributor_id": 1,
    "territory_id": 1,
    "country_code": "VNM",
    "created_by": 1
  }'
```

### Sync Offline Draft
```bash
curl -X POST http://localhost:3001/api/v1/outlets/sync \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{
    "code": "OL-002",
    "name": "Quán Bà Tư",
    "phone": "0909876543",
    "province_code": "HCM",
    "district_code": "002",
    "ward_code": "00010",
    "latitude": 10.762622,
    "longitude": 106.660172,
    "distributor_id": 1,
    "territory_id": 2,
    "country_code": "VNM",
    "local_id": "550e8400-e29b-41d4-a716-446655440000",
    "created_by": 1
  }'
```

### Check Duplicate
```bash
curl -X POST http://localhost:3001/api/v1/outlets/check-duplicate \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0901234567",
    "latitude": 21.028511,
    "longitude": 105.804817,
    "radius_meters": 50,
    "distributor_id": 1,
    "territory_id": 1
  }'
```

### Approve Outlet
```bash
curl -X PATCH "http://localhost:3001/api/v1/outlets/123/approve?distributor_id=1&territory_id=1" \
  -H "X-User-Id: 5"
```

## Testing
```bash
make test
```

## Monitoring
- `/metrics` - Prometheus metrics endpoint
- Sentry integration for error tracking
- Health check at `/health`

## Integration with Mobile App

This service is consumed by `dms-mobile-offline` Flutter app:
- API base URL: `http://localhost:3001/api/v1` (dev) or `https://api.dms.com/api/v1` (prod)
- Authentication: Mobile app sends `X-User-Id` header for approval actions
- Scoping: Mobile app reads `distributor_id`/`territory_id` from `UserSession` and sends in query params

## License
Proprietary - Internal use only