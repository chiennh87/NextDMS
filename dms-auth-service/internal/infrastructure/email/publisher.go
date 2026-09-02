package email

import (
	"context"

	"github.com/nextdms/authservice/internal/domain/entity"
	"go.uber.org/zap"
)

// InProcessEmailPublisher publish email vào channel trong process
type InProcessEmailPublisher struct {
	channel chan<- *entity.EmailEvent
	logger  *zap.Logger
}

func NewInProcessEmailPublisher(channel chan<- *entity.EmailEvent, logger *zap.Logger) *InProcessEmailPublisher {
	return &InProcessEmailPublisher{channel: channel, logger: logger}
}

func (p *InProcessEmailPublisher) PublishEmail(ctx context.Context, event *entity.EmailEvent) error {
	select {
	case p.channel <- event:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}
