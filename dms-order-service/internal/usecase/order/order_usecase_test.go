package order

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"

	"dms-order-service/internal/domain/order"
)

func validSalesmanID() string { return "a1b2c3d4-e5f6-7890-abcd-ef1234567890" }
func validOutletID() string   { return "b1c2d3e4-f5a6-7890-bcde-f12345678901" }
func validSKUID() string      { return "c1d2e3f4-a5b6-7890-cdef-123456789012" }

// Test successful order creation
func TestCreateOrder_Success(t *testing.T) {
	repo := &mockRepo{
		CreateFn: func(ctx context.Context, o *order.Order) error {
			return nil
		},
	}
	cache := &mockCache{
		CheckStockFn: func(ctx context.Context, skuID string, qty int) (bool, error) {
			return true, nil
		},
	}
	queue := &mockQueue{
		PublishOrderCreatedFn: func(ctx context.Context, o *order.Order) error {
			return nil
		},
	}

	useCase := NewOrderUseCase(repo, cache, queue)
	input := CreateOrderInput{
		SalesmanID: validSalesmanID(),
		OutletID:   validOutletID(),
		Items: []order.OrderItem{
			{SKUID: validSKUID(), Quantity: 2, Price: 100.0},
		},
		GPSLat:  10.5,
		GPSLong: 101.2,
	}

	result, err := useCase.CreateOrder(context.Background(), input)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, validSalesmanID(), result.SalesmanID)
	assert.Equal(t, "PENDING", result.Status)
}

// Test insufficient stock
func TestCreateOrder_InsufficientStock(t *testing.T) {
	repo := &mockRepo{
		CreateFn: func(ctx context.Context, o *order.Order) error {
			return nil
		},
	}
	cache := &mockCache{
		CheckStockFn: func(ctx context.Context, skuID string, qty int) (bool, error) {
			return false, nil
		},
	}
	queue := &mockQueue{}

	useCase := NewOrderUseCase(repo, cache, queue)
	input := CreateOrderInput{
		SalesmanID: validSalesmanID(),
		OutletID:   validOutletID(),
		Items: []order.OrderItem{
			{SKUID: validSKUID(), Quantity: 100, Price: 50.0},
		},
		GPSLat:  12.0,
		GPSLong: 102.0,
	}

	result, err := useCase.CreateOrder(context.Background(), input)

	assert.Error(t, err)
	assert.Nil(t, result)
	assert.Contains(t, err.Error(), "sản phẩm không đủ tồn kho")
}

// Test empty items validation
func TestCreateOrder_EmptyItems(t *testing.T) {
	repo := &mockRepo{}
	cache := &mockCache{}
	queue := &mockQueue{}

	useCase := NewOrderUseCase(repo, cache, queue)
	input := CreateOrderInput{
		SalesmanID: validSalesmanID(),
		OutletID:   validOutletID(),
		Items:      []order.OrderItem{},
		GPSLat:     10.0,
		GPSLong:    101.0,
	}

	result, err := useCase.CreateOrder(context.Background(), input)

	assert.Error(t, err)
	assert.Nil(t, result)
	assert.Contains(t, err.Error(), "đơn hàng phải có ít nhất 1 sản phẩm")
}

// Test repository error
func TestCreateOrder_RepositoryError(t *testing.T) {
	repo := &mockRepo{
		CreateFn: func(ctx context.Context, o *order.Order) error {
			return fmt.Errorf("lỗi kết nối database")
		},
	}
	cache := &mockCache{
		CheckStockFn: func(ctx context.Context, skuID string, qty int) (bool, error) {
			return true, nil
		},
	}
	queue := &mockQueue{}

	useCase := NewOrderUseCase(repo, cache, queue)
	input := CreateOrderInput{
		SalesmanID: validSalesmanID(),
		OutletID:   validOutletID(),
		Items: []order.OrderItem{
			{SKUID: validSKUID(), Quantity: 1, Price: 100.0},
		},
		GPSLat:  10.0,
		GPSLong: 101.0,
	}

	result, err := useCase.CreateOrder(context.Background(), input)

	assert.Error(t, err)
	assert.Nil(t, result)
	assert.Contains(t, err.Error(), "lỗi kết nối database")
}

// Test cache error
func TestCreateOrder_CacheError(t *testing.T) {
	repo := &mockRepo{}
	cache := &mockCache{
		CheckStockFn: func(ctx context.Context, skuID string, qty int) (bool, error) {
			return false, fmt.Errorf("lỗi kết nối Redis")
		},
	}
	queue := &mockQueue{}

	useCase := NewOrderUseCase(repo, cache, queue)
	input := CreateOrderInput{
		SalesmanID: validSalesmanID(),
		OutletID:   validOutletID(),
		Items: []order.OrderItem{
			{SKUID: validSKUID(), Quantity: 1, Price: 100.0},
		},
		GPSLat:  10.0,
		GPSLong: 101.0,
	}

	result, err := useCase.CreateOrder(context.Background(), input)

	assert.Error(t, err)
	assert.Nil(t, result)
	assert.Contains(t, err.Error(), "lỗi kiểm tra tồn kho")
}

// Test multiple items order
func TestCreateOrder_MultipleItems(t *testing.T) {
	repo := &mockRepo{
		CreateFn: func(ctx context.Context, o *order.Order) error {
			return nil
		},
	}
	cache := &mockCache{
		CheckStockFn: func(ctx context.Context, skuID string, qty int) (bool, error) {
			return true, nil
		},
	}
	queue := &mockQueue{
		PublishOrderCreatedFn: func(ctx context.Context, o *order.Order) error {
			return nil
		},
	}

	useCase := NewOrderUseCase(repo, cache, queue)
	input := CreateOrderInput{
		SalesmanID: validSalesmanID(),
		OutletID:   validOutletID(),
		Items: []order.OrderItem{
			{SKUID: validSKUID(), Quantity: 2, Price: 100.0},
			{SKUID: "d1e2f3a4-b5c6-7890-def1-234567890123", Quantity: 1, Price: 200.0},
			{SKUID: "e1f2a3b4-c5d6-7890-ef12-345678901234", Quantity: 3, Price: 50.0},
		},
		GPSLat:  13.0,
		GPSLong: 103.0,
	}

	result, err := useCase.CreateOrder(context.Background(), input)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, 3, len(result.Items))
	assert.Equal(t, 550.0, result.TotalAmount)
}

// Test timeout
func TestCreateOrder_Timeout(t *testing.T) {
	repo := &mockRepo{}
	cache := &mockCache{
		CheckStockFn: func(ctx context.Context, skuID string, qty int) (bool, error) {
			select {
			case <-ctx.Done():
				return false, ctx.Err()
			case <-time.After(2 * time.Second):
				return true, nil
			}
		},
	}
	queue := &mockQueue{}

	useCase := NewOrderUseCase(repo, cache, queue)
	input := CreateOrderInput{
		SalesmanID: validSalesmanID(),
		OutletID:   validOutletID(),
		Items: []order.OrderItem{
			{SKUID: validSKUID(), Quantity: 1, Price: 100.0},
		},
		GPSLat:  10.0,
		GPSLong: 101.0,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()

	result, err := useCase.CreateOrder(ctx, input)

	assert.Error(t, err)
	assert.Nil(t, result)
}