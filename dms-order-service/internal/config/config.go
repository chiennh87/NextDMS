package config

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

// Config chứa toàn bộ cấu hình của dms-order-service, đọc từ môi trường
// (thường qua .env hoặc Kubernetes Secrets). Không dùng thư viện bên ngoài
// để giữ binary nhẹ và tránh phụ thuộc không cần thiết.
type Config struct {
	// HTTP server
	HTTPPort string // ví dụ ":8080"

	// Database
	PostgresDSN string

	// Redis
	RedisAddr     string
	RedisPassword string
	RedisDB       int

	// Message Queue (Kafka)
	KafkaBrokers []string
	KafkaTopic   string

	// Order processing
	OrderTimeout time.Duration

	// Rate limiting (requests per minute per IP)
	RateLimitPerMinute int

	// Sentry (error tracking)
	SentryDSN              string
	SentryEnvironment      string
	SentryTracesSampleRate float64
	SentryEnabled          bool

	// Service metadata
	ServiceName    string
	ServiceVersion string
}

// Load đọc cấu hình từ biến môi trường. Cung cấp giá trị mặc định
// an toàn để service có thể chạy được ngay cả khi không có .env.
func Load() (*Config, error) {
	c := &Config{
		HTTPPort:           ":" + strconv.Itoa(envIntDefault("PORT", 8080)),
		PostgresDSN:        envOrDefault("POSTGRES_DSN", "host=localhost user=postgres password=postgres dbname=dms_sslmode=disable"),
		RedisAddr:          envOrDefault("REDIS_ADDR", "localhost:6379"),
		RedisPassword:      os.Getenv("REDIS_PASSWORD"),
		RedisDB:            envIntDefault("REDIS_DB", 0),
		KafkaBrokers:       splitCSV(envOrDefault("KAFKA_BROKERS", "localhost:9092")),
		KafkaTopic:         envOrDefault("KAFKA_TOPIC", "dms.orders.v1"),
		OrderTimeout:       time.Duration(envIntDefault("ORDER_TIMEOUT_SEC", 5)) * time.Second,
		RateLimitPerMinute: envIntDefault("RATE_LIMIT_PER_MINUTE", 30),

		// Sentry
		SentryDSN:              os.Getenv("SENTRY_DSN"),
		SentryEnvironment:      envOrDefault("SENTRY_ENV", "production"),
		SentryTracesSampleRate: envFloatDefault("SENTRY_TRACES_SAMPLE_RATE", 0.1),
		SentryEnabled:          os.Getenv("SENTRY_DSN") != "",

		// Service metadata
		ServiceName:    envOrDefault("SERVICE_NAME", "dms-order-service"),
		ServiceVersion: envOrDefault("SERVICE_VERSION", "1.0.0"),
	}
	if c.PostgresDSN == "" || c.RedisAddr == "" {
		return nil, fmt.Errorf("POSTGRES_DSN và REDIS_ADDR là bắt buộc")
	}
	return c, nil
}

func envOrDefault(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func envIntDefault(key string, def int) int {
	if v, ok := os.LookupEnv(key); ok {
		if value, err := strconv.Atoi(v); err == nil {
			return value
		}
	}
	return def
}

func envFloatDefault(key string, def float64) float64 {
	if v, ok := os.LookupEnv(key); ok {
		if f, err := strconv.ParseFloat(v, 64); err == nil {
			return f
		}
	}
	return def
}

func splitCSV(s string) []string {
	if s == "" {
		return nil
	}
	var out []string
	for _, p := range []string{} {
		_ = p
	}
	// Tách theo dấu phẩy đơn giản (không cần CSV parser).
	start := 0
	for i, c := range s {
		if c == ',' {
			out = append(out, s[start:i])
			start = i + 1
		}
	}
	out = append(out, s[start:])
	return out
}
