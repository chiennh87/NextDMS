package order

import (
	"context"
	"fmt"
	"time"

	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"

	"dms-order-service/internal/domain/order"
)

// UseCase định nghĩa nghiệp vụ tạo đơn hàng - tầng Delivery (HTTP handler)
// chỉ được phép phụ thuộc vào interface này, không phụ thuộc implement cụ thể.
type UseCase interface {
	CreateOrder(ctx context.Context, input CreateOrderInput) (*order.Order, error)
}

// orderUseCase là implement duy nhất của UseCase, chứa toàn bộ business logic.
type orderUseCase struct {
	repo     order.Repository
	cache    order.CacheRepository
	queue    order.MessageQueue
	validate *validator.Validate
	timeout  time.Duration
}

// NewOrderUseCase khởi tạo orderUseCase, tiêm (inject) các adapter cụ thể
// (Postgres/Redis/Kafka) thông qua interface để dễ dàng viết Unit Test (mock).
func NewOrderUseCase(r order.Repository, c order.CacheRepository, q order.MessageQueue) UseCase {
	return &orderUseCase{
		repo:     r,
		cache:    c,
		queue:    q,
		validate: validator.New(),
		timeout:  5 * time.Second, // Timeout ngắn để tránh nghẽn luồng giờ cao điểm 8h-10h
	}
}

// CreateOrderInput là dữ liệu đầu vào khi Salesman tạo đơn hàng từ App/Web.
type CreateOrderInput struct {
	SalesmanID string            `json:"salesman_id" validate:"required,uuid4"`
	OutletID   string            `json:"outlet_id" validate:"required,uuid4"`
	Items      []order.OrderItem `json:"items" validate:"required,min=1,dive"`
	GPSLat     float64           `json:"gps_lat" validate:"required,gte=-90,lte=90"`
	GPSLong    float64           `json:"gps_long" validate:"required,gte=-180,lte=180"`
}

// CreateOrder xử lý toàn bộ luồng tạo đơn hàng:
//  1. Validate dữ liệu đầu vào (struct tag).
//  2. Kiểm tra tồn kho từ Redis Cache (đọc nhanh, không chạm DB chính).
//  3. Lưu đơn hàng vào Postgres (nguồn dữ liệu chuẩn - source of truth).
//  4. Bắn sự kiện OrderCreated vào Message Queue bất đồng bộ (không chặn luồng chính).
func (u *orderUseCase) CreateOrder(ctx context.Context, input CreateOrderInput) (*order.Order, error) {
	// Áp dụng context timeout để tránh 1 request bị treo làm nghẽn cả pool
	// connection DB/Redis trong giờ cao điểm.
	ctx, cancel := context.WithTimeout(ctx, u.timeout)
	defer cancel()

	// 1. Validate đầu vào theo struct tag (required, uuid4, gt=0, ...)
	if err := u.validate.Struct(input); err != nil {
		return nil, fmt.Errorf("dữ liệu không hợp lệ: %w", err)
	}
	if len(input.Items) == 0 {
		return nil, order.ErrEmptyItems
	}

	// 2. Kiểm tra tồn kho từ Redis Cache (ưu tiên hiệu năng cao giờ cao điểm)
	// và đồng thời tính tổng tiền đơn hàng dựa trên giá do server xác định
	// (KHÔNG tin tưởng giá client gửi lên để tránh gian lận đơn giá).
	var totalAmount float64
	for i, item := range input.Items {
		available, err := u.cache.CheckStock(ctx, item.SKUID, item.Quantity)
		if err != nil {
			return nil, fmt.Errorf("lỗi kiểm tra tồn kho SKU %s: %w", item.SKUID, err)
		}
		if !available {
			return nil, fmt.Errorf("%w: %s", order.ErrOutOfStock, item.SKUID)
		}
		totalAmount += item.Price * float64(item.Quantity)
		input.Items[i] = item
	}

	// 3. Tạo Entity Order với ID sinh bằng UUID v4 chuẩn (tránh trùng lặp
	// khi có nhiều instance service cùng chạy - stateless horizontal scaling).
	newOrder := &order.Order{
		ID:          uuid.NewString(),
		OrderNumber: fmt.Sprintf("ORD-%d", time.Now().UnixNano()),
		SalesmanID:  input.SalesmanID,
		OutletID:    input.OutletID,
		Items:       input.Items,
		TotalAmount: totalAmount,
		FinalAmount: totalAmount, // Chưa áp dụng chiết khấu/khuyến mãi ở bước này
		Status:      order.StatusPending,
		GPSLat:      input.GPSLat,
		GPSLong:     input.GPSLong,
		CreatedAt:   time.Now(),
	}

	// 4. Lưu vào DB (Postgres) - trong thực tế Repository.Create nên chạy
	// trong 1 DB Transaction bao gồm cả việc insert order_items.
	if err := u.repo.Create(ctx, newOrder); err != nil {
		return nil, fmt.Errorf("không thể lưu đơn hàng: %w", err)
	}

	// 5. Gửi Event vào Message Queue (Async) - dùng context.Background() vì
	// ctx của request có thể đã bị cancel/hết timeout khi goroutine chạy tới.
	// Không chặn luồng chính (response trả về ngay sau khi lưu DB thành công).
	go func(publishOrder *order.Order) {
		bgCtx, bgCancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer bgCancel()
		if err := u.queue.PublishOrderCreated(bgCtx, publishOrder); err != nil {
			// TODO: thay bằng logger (zap) thực tế + cơ chế retry/DLQ (Dead Letter Queue)
			fmt.Printf("[WARN] publish order %s to queue failed: %v\n", publishOrder.ID, err)
		}
	}(newOrder)

	return newOrder, nil
}

