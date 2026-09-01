package handlers

import (
	"context"
	"net/http"
	"sync/atomic"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

// HealthStatus represents the health check response
type HealthStatus struct {
	Status     string            `json:"status"`
	Timestamp  time.Time         `json:"timestamp"`
	Version    string            `json:"version"`
	Uptime     string            `json:"uptime"`
	Components map[string]string `json:"components"`
}

// HealthHandler provides health check endpoints
type HealthHandler struct {
	db        *pgxpool.Pool
	redis     *redis.Client
	startTime time.Time
	version   string
	isReady   atomic.Bool
}

// NewHealthHandler creates a new health check handler
func NewHealthHandler(db *pgxpool.Pool, redis *redis.Client, version string) *HealthHandler {
	return &HealthHandler{
		db:        db,
		redis:     redis,
		startTime: time.Now(),
		version:   version,
	}
}

// MarkReady marks the service as ready to receive traffic
func (h *HealthHandler) MarkReady() {
	h.isReady.Store(true)
}

// Liveness check - is the service running?
// Returns 200 OK if the process is alive
func (h *HealthHandler) Liveness(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "alive",
		"timestamp": time.Now(),
		"uptime":    time.Since(h.startTime).String(),
	})
}

// Readiness check - is the service ready to handle requests?
// Checks all dependencies (DB, Redis)
func (h *HealthHandler) Readiness(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 2*time.Second)
	defer cancel()

	status := HealthStatus{
		Status:     "ready",
		Timestamp:  time.Now(),
		Version:    h.version,
		Uptime:     time.Since(h.startTime).String(),
		Components: make(map[string]string),
	}

	allHealthy := true

	// Check PostgreSQL
	if h.db != nil {
		if err := h.db.Ping(ctx); err != nil {
			status.Components["postgres"] = "unhealthy: " + err.Error()
			allHealthy = false
		} else {
			status.Components["postgres"] = "healthy"
		}
	}

	// Check Redis
	if h.redis != nil {
		if err := h.redis.Ping(ctx).Err(); err != nil {
			status.Components["redis"] = "unhealthy: " + err.Error()
			allHealthy = false
		} else {
			status.Components["redis"] = "healthy"
		}
	}

	// Check ready flag
	if !h.isReady.Load() {
		allHealthy = false
		status.Components["startup"] = "not ready"
	} else {
		status.Components["startup"] = "ready"
	}

	if !allHealthy {
		status.Status = "not_ready"
		c.JSON(http.StatusServiceUnavailable, status)
		return
	}

	c.JSON(http.StatusOK, status)
}

// Health check - combined liveness and readiness
func (h *HealthHandler) Health(c *gin.Context) {
	h.Readiness(c)
}