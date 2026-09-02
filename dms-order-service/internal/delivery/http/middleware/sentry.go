package middleware

import (
	"fmt"
	"net/http"
	"time"

	"github.com/getsentry/sentry-go"
	"github.com/gin-gonic/gin"
)

// SentryMiddleware creates a Gin middleware for Sentry error tracking
func SentryMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Start a new span/transaction for this request
		hub := sentry.NewHub(sentry.CurrentHub().Client(), sentry.NewScope())

		// Store the hub in the context for later use
		c.Set("sentry_hub", hub)

		// Process request
		c.Next()

		// Check if there are any errors
		if len(c.Errors) > 0 {
			// Report each error to Sentry
			for _, err := range c.Errors {
				hub.CaptureException(err.Err)
			}
		} else if c.Writer.Status() >= http.StatusInternalServerError {
			// Capture 5xx errors even if no Gin errors were set
			hub.CaptureMessage(fmt.Sprintf("Server error: %d", c.Writer.Status()))
		}

	}
}

// InitSentry initializes Sentry with the given configuration
func InitSentry(dsn, environment string, sampleRate float64) error {
	if dsn == "" {
		return nil // Sentry is disabled
	}

	err := sentry.Init(sentry.ClientOptions{
		Dsn:              dsn,
		Environment:      environment,
		TracesSampleRate: sampleRate,
		// Enable performance monitoring
		EnableTracing: true,
		// Set the server name
		ServerName: "dms-order-service",
		// Release tracking
		Release: "dms-order-service@1.0.0",
		// Ignore certain errors
		IgnoreTransactions: []string{
			"/healthz",
			"/readyz",
			"/metrics",
		},
		// BeforeSend hook for filtering
		BeforeSend: func(event *sentry.Event, hint *sentry.EventHint) *sentry.Event {
			// Filter out health check errors
			if hint != nil && hint.Request != nil {
				if hint.Request.URL.Path == "/healthz" || hint.Request.URL.Path == "/readyz" {
					return nil
				}
			}
			return event
		},
	})

	if err != nil {
		return fmt.Errorf("failed to initialize Sentry: %w", err)
	}

	return nil
}

// CaptureError captures an error to Sentry with optional context
func CaptureError(c *gin.Context, err error, context map[string]interface{}) {
	if hub, exists := c.Get("sentry_hub"); exists {
		if h, ok := hub.(*sentry.Hub); ok {
			if context != nil {
				h.WithScope(func(scope *sentry.Scope) {
					for k, v := range context {
						scope.SetExtra(k, v)
					}
					h.CaptureException(err)
				})
			} else {
				h.CaptureException(err)
			}
		}
	}
}

// CaptureMessage captures a message to Sentry
func CaptureMessage(c *gin.Context, message string, level sentry.Level) {
	if hub, exists := c.Get("sentry_hub"); exists {
		if h, ok := hub.(*sentry.Hub); ok {
			h.WithScope(func(scope *sentry.Scope) {
				scope.SetLevel(level)
				h.CaptureMessage(message)
			})
		}
	}
}

// Flush sends all pending events to Sentry
func FlushSentry(timeoutSeconds int) bool {
	return sentry.Flush(time.Duration(timeoutSeconds) * time.Second)
}

// SetUser sets user information in Sentry
func SetUser(c *gin.Context, userID, email string) {
	if hub, exists := c.Get("sentry_hub"); exists {
		if h, ok := hub.(*sentry.Hub); ok {
			h.ConfigureScope(func(scope *sentry.Scope) {
				scope.SetUser(sentry.User{
					ID:    userID,
					Email: email,
				})
			})
		}
	}
}
