package middleware

import (
	"github.com/nextdms/authservice/internal/domain/repository"
	"github.com/nextdms/authservice/pkg/response"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// RateLimiter middleware - chống brute force
func RateLimiter(rateLimiter repository.RateLimiterRepository, maxAttempts int, windowSec int) gin.HandlerFunc {
	return func(c *gin.Context) {
		clientIP := c.ClientIP()
		key := "ip:" + clientIP

		allowed, remaining, resetAt, err := rateLimiter.Allow(c.Request.Context(), key, maxAttempts, windowSec)
		if err != nil {
			// Don't block on Redis errors
			c.Next()
			return
		}

		// Set headers
		c.Header("X-RateLimit-Limit", strconv.Itoa(maxAttempts))
		c.Header("X-RateLimit-Remaining", strconv.Itoa(remaining))
		c.Header("X-RateLimit-Reset", strconv.FormatInt(resetAt, 10))

		if !allowed {
			retryAfter := resetAt - time.Now().Unix()
			if retryAfter < 1 {
				retryAfter = 1
			}
			c.Header("Retry-After", strconv.FormatInt(retryAfter, 10))

			response.Error(c, &AppError{
				Code:    "RATE_LIMITED",
				Message: "Too many requests",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

type AppError struct {
	Code    string
	Message string
}

func (e *AppError) Error() string { return e.Message }
