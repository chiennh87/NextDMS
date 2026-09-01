package order

import (
	"context"
	"errors"
	"time"
)

// Order đại diện cho thực thể đơn hàng trong Domain (không phụ thuộc
// framework/DB cụ thể - tuân thủ nguyên tắc Clean Architecture).
type Order struct {
	ID          string      `json:"id"`
	OrderNumber string      `json:"order_number"`
	SalesmanID  string      `json:"salesman_id"`
	OutletID    string      `json:"outlet_id"`
	Items       []OrderItem `json:"items"`
	TotalAmount float64     `json:"total_amount"`
	FinalAmount float64     `json:"final_amount"`
	Status      string      `json:"status"`
	GPSLat      float64     `json:"gps_lat"`
	GPSLong     float64     `json:"gps_long"`
	CreatedAt   time.Time   `json:"created_at"`
}

// Các trạng thái hợp lệ của đơn hàng.
const (
	StatusPending   = "PENDING"
	StatusConfirmed = "CONFIRMED"
	StatusShipped   = "SHIPPED"
	StatusCancelled = "CANCELLED"
)

type OrderItem struct {
	SKUID    string  `json:"sku_id" validate:"required,uuid4"`
	Quantity int     `json:"quantity" validate:"required,gt=0"`
	Price    float64 `json:"price"` // Được usecase gán lại từ giá hệ thống, không tin tưởng giá client gửi lên
}

// Danh sách lỗi nghiệp vụ (business error) dùng chung để tầng delivery (HTTP)
// map sang đúng mã HTTP status thay vì luôn trả về 500 Internal Server Error.
var (
	ErrOutOfStock    = errors.New("sản phẩm không đủ tồn kho")
	ErrOutletInvalid = errors.New("điểm bán không hợp lệ hoặc đã ngừng hoạt động")
	ErrEmptyItems    = errors.New("đơn hàng phải có ít nhất 1 sản phẩm")
)

// Repository interface để Adapter triển khai (Postgres).
type Repository interface {
	Create(ctx context.Context, order *Order) error
}

// CacheRepository interface cho Redis - dùng để kiểm tra tồn kho nhanh
// (đã được đồng bộ định kỳ từ hệ thống kho/ERP sang Redis).
type CacheRepository interface {
	CheckStock(ctx context.Context, skuID string, qty int) (bool, error)
}

// MessageQueue interface cho Kafka/RabbitMQ - publish event bất đồng bộ.
type MessageQueue interface {
	PublishOrderCreated(ctx context.Context, order *Order) error
}

