// cmd/main.go - DMS Outlet Service - Enterprise FMCG
// Features: Approval Workflow, Offline-First Sync, Multi-Country, Data Scoping
package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/getsentry/sentry-go"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"github.com/nextdms/dms-outlet-service/internal/delivery/http/handler"
	"github.com/nextdms/dms-outlet-service/internal/repository/postgres"
	"github.com/nextdms/dms-outlet-service/internal/usecase"
)

func main() {
	// Initialize Sentry for error tracking
	if os.Getenv("SENTRY_DSN") != "" {
		if err := sentry.Init(sentry.ClientOptions{
			Dsn:              os.Getenv("SENTRY_DSN"),
			Environment:      os.Getenv("ENV"),
			TracesSampleRate: 0.1,
		}); err != nil {
			log.Printf("Sentry init failed: %v", err)
		}
	}

	// Database connection
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://postgres:postgres@localhost:5432/dms?sslmode=disable"
	}

	ctx := context.Background()
	repo, err := postgres.NewOutletRepository(ctx, dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer repo.Close()

	// Use cases
	outletUC := usecase.NewOutletUseCase(repo)

	// Handlers
	outletHandler := handler.NewOutletHandler(outletUC)

	// Gin router
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(corsMiddleware())
	r.Use(requestLogger())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "dms-outlet-service"})
	})

	// Metrics endpoint
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// API v1 routes
	v1 := r.Group("/api/v1")
	{
		// Enterprise: Sync endpoints (Offline-First)
		v1.POST("/outlets/sync", outletHandler.SyncOutlet)
		v1.PATCH("/outlets/sync-status", outletHandler.UpdateSyncStatus)
		v1.GET("/outlets/pending-sync", outletHandler.GetPendingSyncOutlets)

		// Enterprise: CRUD endpoints với Scoping + Approval
		v1.POST("/outlets", outletHandler.CreateOutlet)
		v1.GET("/outlets", outletHandler.ListOutlets)
		v1.GET("/outlets/:id", outletHandler.GetOutlet)
		v1.PUT("/outlets/:id", outletHandler.UpdateOutlet)
		v1.DELETE("/outlets/:id", outletHandler.DeleteOutlet)
		v1.POST("/outlets/check-duplicate", outletHandler.CheckDuplicate)

		// Enterprise: Approval workflow
		v1.PATCH("/outlets/:id/approve", outletHandler.ApproveOutlet)
		v1.PATCH("/outlets/:id/reject", outletHandler.RejectOutlet)

		// Master data với Multi-Country
		v1.GET("/value-set-values", outletHandler.GetValueSetValues)
		v1.GET("/provinces", outletHandler.GetProvinces)
		v1.GET("/districts", outletHandler.GetDistricts)
		v1.GET("/wards", outletHandler.GetWards)

		// Media upload
		v1.POST("/outlets/upload-photo", outletHandler.UploadPhoto)
	}

	// Server
	port := os.Getenv("PORT")
	if port == "" {
		port = "3001"
	}

	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      r,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown
	go func() {
		log.Printf("DMS Outlet Service starting on port %s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}
	log.Println("Server exited")
}

// Middlewares
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Distributor-ID, X-Territory-ID, X-Country-Code")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}

func requestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		c.Next()
		latency := time.Since(start)
		status := c.Writer.Status()
		log.Printf("%s %s %d %v", c.Request.Method, path, status, latency)
	}
}