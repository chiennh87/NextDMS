package queue

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/segmentio/kafka-go"

	"dms-order-service/internal/domain/order"
)

// kafkaQueue implement order.MessageQueue, publish OrderCreated event.
// Sử dụng async writer (AsyncClose) + batching (batch.size/batch.timeout)
// để tối ưu throughput khi 1000+ salesman cùng tạo đơn hàng giờ cao điểm.
type kafkaQueue struct {
	writer *kafka.Writer
	topic  string
}

// NewKafkaQueue tạo Kafka writer với config tối ưu:
// - AsyncClose: không block khi Close
// - Batch.Size: gom nhóm message để giảm I/O
// - Batch.Timeout: tối đa 10ms trước khi flush batch
// - Acks: All (đảm bảo leader + ISR replicas đều nhận được)
// - minBytes: 1, maxBytes: 10MB (tối ưu throughput)
func NewKafkaQueue(brokers []string, topic string) (*kafkaQueue, error) {
	if len(brokers) == 0 {
		return nil, fmt.Errorf("ít nhất 1 broker Kafka là bắt buộc")
	}
	writer := &kafka.Writer{
		Addr:         kafka.TCP(brokers...),
		Topic:        topic,
		Balancer:     &kafka.LeastBytes{}, // Phân phối message đồng đều qua partition
		Async:        true,
		BatchSize:    500,
		BatchTimeout: 10 * time.Millisecond,
		RequiredAcks: kafka.RequireAll, // Đảm bảo message không bị mất
		Compression:  kafka.Snappy,     // Snappy cho throughput cao
	}
	return &kafkaQueue{writer: writer, topic: topic}, nil
}

// PublishOrderCreated serialize Order sang JSON và publish vào topic.
// Key = order.ID để đảm bảo thứ tự message cho cùng 1 order (partitioning).
func (k *kafkaQueue) PublishOrderCreated(ctx context.Context, o *order.Order) error {
	payload, err := json.Marshal(o)
	if err != nil {
		return fmt.Errorf("marshal order %s: %w", o.ID, err)
	}

	msg := kafka.Message{
		Key:   []byte(o.ID),
		Value: payload,
	}
	if err := k.writer.WriteMessages(ctx, msg); err != nil {
		return fmt.Errorf("gửi message order %s: %w", o.ID, err)
	}
	return nil
}

// Close flush remaining messages và đóng writer.
func (k *kafkaQueue) Close() error {
	return k.writer.Close()
}

// Compile-time check.
var _ order.MessageQueue = (*kafkaQueue)(nil)
