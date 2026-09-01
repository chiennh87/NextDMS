package order

import (
	"context"

	"dms-order-service/internal/domain/order"
)

// mockRepo implements order.Repository interface
type mockRepo struct {
	CreateFn func(ctx context.Context, o *order.Order) error
}

func (m *mockRepo) Create(ctx context.Context, o *order.Order) error {
	if m.CreateFn != nil {
		return m.CreateFn(ctx, o)
	}
	return nil
}

// mockCache implements order.CacheRepository interface
type mockCache struct {
	CheckStockFn func(ctx context.Context, skuID string, qty int) (bool, error)
}

func (m *mockCache) CheckStock(ctx context.Context, skuID string, qty int) (bool, error) {
	if m.CheckStockFn != nil {
		return m.CheckStockFn(ctx, skuID, qty)
	}
	return true, nil
}

// mockQueue implements order.MessageQueue interface
type mockQueue struct {
	PublishOrderCreatedFn func(ctx context.Context, o *order.Order) error
}

func (m *mockQueue) PublishOrderCreated(ctx context.Context, o *order.Order) error {
	if m.PublishOrderCreatedFn != nil {
		return m.PublishOrderCreatedFn(ctx, o)
	}
	return nil
}