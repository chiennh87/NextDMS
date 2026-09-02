package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"dms-order-service/internal/config"
	"dms-order-service/internal/delivery/http/handlers"
	orderhandler "dms-order-service/internal/delivery/http/v1"
	"dms-order-service/internal/delivery/http/middleware"
	"dms-order-service/internal/infra/cache"
	"dms-order-service/internal/infra/queue"
	"dms-order-service/internal/infra/repository"
	"dms-order-service/internal/usecase/order"
)

// main là entrypoint chính của dịch vụ.
func main() {
	// 1. Load configuration từ môi trường
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 1.1 Khởi tạo Sentry (nếu có DSN)
	if cfg.SentryEnabled {
		if err := middleware.InitSentry(cfg.SentryDSN, cfg.SentryEnvironment, cfg.SentryTracesSampleRate); err != nil {
			log.Printf("⚠️ Failed to init Sentry (continuing without it): %v", err)
		}
	}

	// 2. Khởi tạo các dependency (singleton pattern)
	// Postgres repository - lấy cả pool để wire vào health check
	repo, dbPool, err := repository.NewPostgresOrderRepository(cfg.PostgresDSN)
	if err != nil {
		log.Fatalf("Failed to create Postgres repository: %v", err)
	}

	// Redis cache - lấy cả client để wire vào health check
	cacheImpl, redisClient, err := cache.NewRedisCache(cfg.RedisAddr, cfg.RedisPassword, cfg.RedisDB)
	if err != nil {
		log.Fatalf("Failed to create Redis cache: %v", err)
	}

	// Kafka queue
	queueImpl, err := queue.NewKafkaQueue(cfg.KafkaBrokers, cfg.KafkaTopic)
	if err != nil {
		log.Fatalf("Failed to create Kafka queue: %v", err)
	}

	// Use case (single instance, stateless)
	useCase := order.NewOrderUseCase(repo, cacheImpl, queueImpl)

	// 2.1 Khởi tạo Metrics (Prometheus) cho HTTP + Order domain
	metrics := handlers.NewMetrics(cfg.ServiceName)

	// 2.2 Khởi tạo HealthHandler với db pool + redis client
	healthHandler := handlers.NewHealthHandler(dbPool, redisClient, cfg.ServiceVersion)
	healthHandler.MarkReady()

	// 3. Xây dựng router với đầy đủ middleware:
	//    - Sentry (nếu enabled)
	//    - Metrics (HTTP request count/duration)
	//    - Recovery (panic safety)
	//    - Logger (request log)
	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(metrics.Middleware())

	if cfg.SentryEnabled {
		router.Use(middleware.SentryMiddleware())
	}

	// Chỉ log những request không phải /metrics, /healthz, /readyz (giảm noise)
	router.Use(gin.LoggerWithConfig(gin.LoggerConfig{
		SkipPaths: []string{"/metrics", "/healthz", "/readyz"},
	}))

	// 3.1 Health check endpoints (không qua rate-limit, không qua metrics skip)
	router.GET("/healthz", healthHandler.Liveness)
	router.GET("/readyz", healthHandler.Readiness)
	router.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// 3.2 API v1 group - áp dụng rate-limit theo salesman
	v1 := router.Group("/api/v1")
	v1.Use(middleware.RateLimitBySalesman(middleware.RateLimitConfig{
		Client: redisClient,
		Limit:  cfg.RateLimitPerMinute,
	}))
	v1.POST("/orders", orderhandler.NewOrderHandler(useCase).CreateOrder)

	// 4. Main loop (Graceful shutdown)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Listen on HTTP server
	server := &http.Server{
		Addr:    cfg.HTTPPort,
		Handler: router,
	}

	// Start server
	go func() {
		log.Println("🚀 Server starting on port", cfg.HTTPPort)
		if err := server.ListenAndServe(); err != nil && ctx.Err() == nil {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal (Ctrl+C) để thực hiện graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("🛑 Shutdown signal received, shutting down...")
	cancel()

	// Flush Sentry events trước khi tắt (2s timeout)
	if cfg.SentryEnabled {
		middleware.FlushSentry(2)
	}

	// Graceful shutdown: wait 5 seconds cho connections đang hoạt động
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()

	// Force close if still running
	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	}

	// Đóng resources (close DB pool, Redis client, Kafka writer)
	if err := queueImpl.Close(); err != nil {
		log.Printf("Error closing Kafka queue: %v", err)
	}
	if err := cacheImpl.Close(); err != nil {
		log.Printf("Error closing Redis cache: %v", err)
	}
	repo.Close()

	log.Println("✅ Service stopped gracefully")
}
