package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"dms-order-service/internal/domain/order"
)

// postgresOrderRepository implement order.Repository interface, lưu đơn hàng
// vào PostgreSQL bằng pgx (driver chuẩn, hỗ trợ connection pool).
type postgresOrderRepository struct {
	db *pgxpool.Pool
}

// NewPostgresOrderRepository tạo pool kết nối PG. Pool được thiết kế để
// tối ưu cho traffic cao: 1 pool chia sẻ cho toàn bộ instance (stateless),
// không mở kết nối mới cho mỗi request.
// Trả về cả repository và pool để HealthHandler có thể check DB connectivity.
func NewPostgresOrderRepository(dsn string) (*postgresOrderRepository, *pgxpool.Pool, error) {
	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, nil, fmt.Errorf("parse postgres DSN: %w", err)
	}
	// Tối ưu pool cho traffic cao (1000 salesman, 100k outlets, peak 8h-10h)
	cfg.MaxConns = 50
	cfg.MinConns = 10
	cfg.ConnConfig.ConnectTimeout = 5 * time.Second
	cfg.ConnConfig.RuntimeParams["application_name"] = "dms-order-service"

	pool, err := pgxpool.NewWithConfig(context.Background(), cfg)
	if err != nil {
		return nil, nil, fmt.Errorf("create postgres pool: %w", err)
	}
	return &postgresOrderRepository{db: pool}, pool, nil
}

// Create lưu 1 order mới vào DB. Sử dụng transaction để đảm bảo tính
// atomicity: insert order + insert order_items cùng một lúc hoặc rollback cả hai.
func (r *postgresOrderRepository) Create(ctx context.Context, o *order.Order) error {
	// Bắt transaction với timeout 3s (đảm bảo không bị treo trong giờ cao điểm).
	tx, err := r.db.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.ReadCommitted, AccessMode: pgx.ReadWrite})
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	// 1. Insert orders
	const qOrder = `
		INSERT INTO orders (
			id, order_number, salesman_id, outlet_id,
			total_amount, discount_amount, final_amount,
			gps_lat, gps_long, status
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`
	if _, err := tx.Exec(ctx, qOrder,
		o.ID, o.OrderNumber, o.SalesmanID, o.OutletID,
		o.TotalAmount, 0, o.FinalAmount,
		o.GPSLat, o.GPSLong, o.Status,
	); err != nil {
		if pgErr, ok := err.(*pgconn.PgError); ok {
			return fmt.Errorf("insert order: %w (code: %s)", pgErr, pgErr.Code)
		}
		return fmt.Errorf("insert order: %w", err)
	}

	// 2. Insert order_items
	const qItem = `
		INSERT INTO order_items (order_id, sku_id, quantity, price_at_order, total_price)
		VALUES ($1, $2, $3, $4, $5)
	`
	for _, item := range o.Items {
		if _, err := tx.Exec(ctx, qItem,
			o.ID, item.SKUID, item.Quantity, item.Price, item.Price*float64(item.Quantity),
		); err != nil {
			return fmt.Errorf("insert order item: %w", err)
		}
	}

	// Commit transaction
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}
	return nil
}

// Close đóng pool, giải phóng tài nguyên.
func (r *postgresOrderRepository) Close() {
	if r.db != nil {
		r.db.Close()
	}
}

// Helper: parse string sang uuid.UUID (dùng để validate format UUID4 trước khi query).
func parseUUID(s string) (uuid.UUID, error) {
	return uuid.Parse(s)
}
