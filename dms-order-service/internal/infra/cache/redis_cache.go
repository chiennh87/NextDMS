package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"

	"dms-order-service/internal/domain/order"
)

// redisCache implement order.CacheRepository, kiểm tra tồn kho từ Redis.
// Redis key convention: stock:{sku_id} -> JSON {qty: int}
type redisCache struct {
	client *redis.Client
	ttl    time.Duration // TTL mặc định cho cache stock
}

// NewRedisCache khởi tạo Redis client. Cấu hình pool connection tối ưu
// cho traffic cao: pipeline batch nếu cần, timeout 200ms.
func NewRedisCache(addr, password string, db int) (*redisCache, error) {
	client := redis.NewClient(&redis.Options{
		Addr:         addr,
		Password:     password,
		DB:           db,
		PoolSize:     100, // Số lượng connection tối đa (tăng cho giờ cao điểm)
		MinIdleConns: 20,  // Giữ sẵn idle connection
		ReadTimeout:  200 * time.Millisecond,
		WriteTimeout: 200 * time.Millisecond,
	})

	// Ping kiểm tra kết nối
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("redis ping: %w", err)
	}
	return &redisCache{client: client, ttl: 5 * time.Minute}, nil
}

// CheckStock kiểm tra xem SKU có đủ số lượng trong cache hay không.
// Key: "stock:{sku_id}". Value: {"qty": 1000}
func (c *redisCache) CheckStock(ctx context.Context, skuID string, qty int) (bool, error) {
	key := "stock:" + skuID
	data, err := c.client.Get(ctx, key).Bytes()
	if err == redis.Nil {
		// Cache miss => không đủ tồn kho (hoặc gọi service kho để fetch)
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("redis get %s: %w", key, err)
	}

	var stock struct {
		Qty int `json:"qty"`
	}
	if err := json.Unmarshal(data, &stock); err != nil {
		return false, fmt.Errorf("unmarshal stock JSON: %w", err)
	}
	return stock.Qty >= qty, nil
}

// SetStock ghi stock vào Redis (dùng cho sync từ service kho).
func (c *redisCache) SetStock(ctx context.Context, skuID string, qty int) error {
	key := "stock:" + skuID
	data, _ := json.Marshal(struct{ Qty int }{Qty: qty})
	return c.client.Set(ctx, key, data, c.ttl).Err()
}

// Close đóng Redis client.
func (c *redisCache) Close() error {
	return c.client.Close()
}

// Compile-time interface compliance check.
var _ order.CacheRepository = (*redisCache)(nil)
