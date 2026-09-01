package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"dms-order-service/internal/config"
	"dms-order-service/internal/infra/cache"
	"dms-order-service/internal/infra/queue"
	"dms-order-service/internal/infra.repository"
	"dms-order-service/internal.delivery.http.v1.order_handler"
)

// main là entrypoint chính của dịch vụ.
func main() {
	// 1. Load configuration từ môi trường
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 2. Khởi tạo các dependency (singleton pattern)
	// Postgres repository
	repo, err := repository.NewPostgresOrderRepository(cfg.PostgresDSN)
	if err != nil {
		log.Fatalf("Failed to create Postgres repository: %v", err)
	}

	// Redis cache
	cache, err := cache.NewRedisCache(cfg.RedisAddr, cfg.RedisPassword, cfg.RedisDB)
	if err != nil {
		log.Fatalf("Failed to create Redis cache: %v", err)
	}

	// Kafka queue
	queue, err := queue.NewKafkaQueue(cfg.KafkaBrokers, cfg.KafkaTopic)
	if err != nil {
		log.Fatalf("Failed to create Kafka queue: %v", err)
	}

	// Use case (single instance, stateless)
	useCase, err := order.NewOrderUseCase(repo, cache, queue)
	if err != nil {
		log.Fatalf("Failed to create order use case: %v", err)
	}

	// 3. Xây dựng router
	router := router.NewRouter(
		useCase:    useCase,
		handler:    order_handler.NewOrderHandler(useCase),
		port:        cfg.HTTPPort,
	)

	// 4. Main loop (Graceful shutdown)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Listen on HTTP server
	server := &http.Server{
		Addr:         ":" + cfg.HTTPPort,
		Handler:      router,
	}

	// Start server
	go func() {
		log.Println("🚀 Server starting on port", cfg.HTTPPort)
		if err := server.ListenAndServe(); err != nil && !ctx.Err() {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal (Ctrl+C) để thực hiện graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("🛑 Shutdown signal received, shutting down...")
	ctx.Stop()

	// Graceful shutdown: wait 5 seconds cho connections đang hoạt động
	time.Sleep(5 * time.Second)

	// Force close if still running
	if err := server.Shutdown(ctx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	}

	log.Println("✅ Service stopped gracefully")
}
