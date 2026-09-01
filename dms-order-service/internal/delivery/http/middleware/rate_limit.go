package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

// RateLimitMiddleware giới hạn số request/phút cho mỗi salesman dựa trên Redis.
// Sử dụng thuật toán Fixed Window Counter (đơn giản, đủ dùng cho FMCG DMS).
//
//   - Key:  rl:{salesman_id}:{minute}
//   - INCR + EXPIRE (atomic) để đếm request trong 1 phút
//   - Trả về 429 Too Many Requests khi vượt ngưỡng
//
// Header response bổ sung:
//   - X-RateLimit-Limit:     giới hạn tối đa
//   - X-RateLimit-Remaining: số request còn lại
//   - Retry-After:           số giây phải chờ (khi bị 429)
type RateLimitConfig struct {
	Client    *redis.Client
	Limit     int           // Số request tối đa trong 1 window (ví dụ: 30/phút)
	Window    time.Duration // Kích thước window (mặc định 1 phút)
	KeyPrefix string        // Tiền tố key trong Redis (mặc định "rl")
}

// RateLimitBySalesman trích xuất salesman_id từ header X-Salesman-ID.
// Trong production, nên lấy từ JWT token đã được middleware Auth giải mã.
func RateLimitBySalesman(cfg RateLimitConfig) gin.HandlerFunc {
	if cfg.Window == 0 {
		cfg.Window = time.Minute
	}
	if cfg.KeyPrefix == "" {
		cfg.KeyPrefix = "rl"
	}

	return func(c *gin.Context) {
		salesmanID := c.GetHeader("X-Salesman-ID")
		if salesmanID == "" {
			// Không có salesman_id thì bỏ qua (middleware Auth sẽ chặn ở bước sau)
			c.Next()
			return
		}

		// Tính key theo window hiện tại (epoch / window seconds)
		now := time.Now().Unix()
		windowSec := int64(cfg.Window.Seconds())
		bucket := now / windowSec
		key := fmt.Sprintf("%s:%s:%d", cfg.KeyPrefix, salesmanID, bucket)

		ctx, cancel := context.WithTimeout(c.Request.Context(), 100*time.Millisecond)
		defer cancel()

		// Dùng pipeline: INCR + EXPIRE (atomic)
		pipe := cfg.Client.Pipeline()
		incrCmd := pipe.Incr(ctx, key)
		pipe.Expire(ctx, key, cfg.Window)
		if _, err := pipe.Exec(ctx); err != nil {
			// Lỗi Redis -> fail open (cho qua) để không ảnh hưởng user
			// Có thể log cảnh báo qua zap logger
			c.Next()
			return
		}

		count := incrCmd.Val()
		remaining := int64(cfg.Limit) - count
		if remaining < 0 {
			remaining = 0
		}

		// Set response headers
		c.Header("X-RateLimit-Limit", strconv.Itoa(cfg.Limit))
		c.Header("X-RateLimit-Remaining", strconv.FormatInt(remaining, 10))

		if count > int64(cfg.Limit) {
			retryAfter := windowSec - (now % windowSec)
			c.Header("Retry-After", strconv.FormatInt(retryAfter, 10))
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error":       "Quá nhiều yêu cầu. Vui lòng thử lại sau.",
				"retry_after": retryAfter,
			})
			return
		}

		c.Next()
	}
}

// RateLimitByIP giới hạn theo IP - dùng cho endpoint không yêu cầu auth.
func RateLimitByIP(cfg RateLimitConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		if ip == "" {
			ip = "unknown"
		}

		now := time.Now().Unix()
		windowSec := int64(cfg.Window.Seconds())
		bucket := now / windowSec
		key := fmt.Sprintf("%s:ip:%s:%d", cfg.KeyPrefix, ip, bucket)

		ctx, cancel := context.WithTimeout(c.Request.Context(), 100*time.Millisecond)
		defer cancel()

		pipe := cfg.Client.Pipeline()
		incrCmd := pipe.Incr(ctx, key)
		pipe.Expire(ctx, key, cfg.Window)
		if _, err := pipe.Exec(ctx); err != nil {
			c.Next()
			return
		}

		count := incrCmd.Val()
		if count > int64(cfg.Limit) {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error": "Quá nhiều yêu cầu từ IP này.",
			})
			return
		}

		c.Next()
	}
}