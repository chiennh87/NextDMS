package email

import (
	"context"
	"sync"
	"time"

	"github.com/nextdms/authservice/internal/domain/entity"
	"go.uber.org/zap"
)

// Worker xử lý email bất đồng bộ
type Worker struct {
	client       *SMTPClient
	emailChan    chan *entity.EmailEvent
	stopChan     chan struct{}
	wg           sync.WaitGroup
	logger       *zap.Logger
	workerCount  int
}

func NewWorker(client *SMTPClient, workerCount int, logger *zap.Logger) *Worker {
	return &Worker{
		client:      client,
		emailChan:   make(chan *entity.EmailEvent, 1000),
		stopChan:    make(chan struct{}),
		logger:      logger,
		workerCount: workerCount,
	}
}

// Channel trả về channel để publish email
func (w *Worker) Channel() chan<- *entity.EmailEvent {
	return w.emailChan
}

// Start khởi động N goroutines xử lý email
func (w *Worker) Start() {
	w.logger.Info("starting email worker", zap.Int("workers", w.workerCount))
	for i := 0; i < w.workerCount; i++ {
		w.wg.Add(1)
		go w.process(i)
	}
}

// Stop graceful shutdown
func (w *Worker) Stop() {
	w.logger.Info("stopping email worker...")
	close(w.stopChan)
	w.wg.Wait()
	w.logger.Info("email worker stopped")
}

func (w *Worker) process(id int) {
	defer w.wg.Done()
	w.logger.Info("email worker started", zap.Int("id", id))
	for {
		select {
		case ev := <-w.emailChan:
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			if err := w.client.Send(ctx, ev); err != nil {
				w.logger.Error("failed to send email", zap.Error(err), zap.String("to", ev.To))
			}
			cancel()
		case <-w.stopChan:
			// Drain remaining emails
			for len(w.emailChan) > 0 {
				ev := <-w.emailChan
				ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
				w.client.Send(ctx, ev)
				cancel()
			}
			w.logger.Info("email worker stopped", zap.Int("id", id))
			return
		}
	}
}
