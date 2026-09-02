package kafka

import (
	"context"
	"github.com/nextdms/authservice/configs"
	"github.com/nextdms/authservice/internal/domain/entity"
	"encoding/json"
	"log"
	"time"

	"github.com/segmentio/kafka-go"
)

type Producer struct {
	writer *kafka.Writer
	topic  string
}

func NewProducer(cfg configs.KafkaConfig) *Producer {
	writer := &kafka.Writer{
		Addr:         kafka.TCP(cfg.Brokers...),
		Topic:        cfg.Topic,
		Balancer:     &kafka.LeastBytes{},
		BatchTimeout: 10 * time.Millisecond,
		Async:        true, // Non-blocking for performance
	}
	return &Producer{writer: writer, topic: cfg.Topic}
}

func (p *Producer) Publish(ctx context.Context, event *entity.AuditEvent) error {
	data, err := json.Marshal(event)
	if err != nil {
		return err
	}

	msg := kafka.Message{
		Key:   []byte(event.UserID), // Partition by user
		Value: data,
		Time:  event.Timestamp,
		Headers: []kafka.Header{
			{Key: "event_type", Value: []byte(event.EventType)},
			{Key: "source", Value: []byte("dms-auth-service")},
		},
	}

	if err := p.writer.WriteMessages(ctx, msg); err != nil {
		log.Printf("Failed to publish Kafka message: %v", err)
		return err
	}

	log.Printf("Published audit event: %s for user: %s", event.EventType, event.UserID)
	return nil
}

func (p *Producer) Close() error {
	return p.writer.Close()
}

// AuditEventPublisher wraps Producer for the repository interface
type AuditEventPublisher struct {
	producer *Producer
}

func NewAuditEventPublisher(producer *Producer) *AuditEventPublisher {
	return &AuditEventPublisher{producer: producer}
}

func (p *AuditEventPublisher) Publish(ctx context.Context, event *entity.AuditEvent) error {
	return p.producer.Publish(ctx, event)
}
