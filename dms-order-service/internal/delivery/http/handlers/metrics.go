package handlers

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// Metrics holds all Prometheus metrics for the order service
type Metrics struct {
	// HTTP metrics
	HTTPRequestsTotal   *prometheus.CounterVec
	HTTPRequestDuration *prometheus.HistogramVec
	HTTPRequestsInFlight prometheus.Gauge

	// Order metrics
	OrdersCreatedTotal   *prometheus.CounterVec
	OrderValue          prometheus.Histogram
	OrderItemsPerOrder  prometheus.Histogram

	// Database metrics
	DBErrorsTotal prometheus.Counter

	// Cache metrics
	CacheHitsTotal   prometheus.Counter
	CacheMissesTotal prometheus.Counter
	CacheErrorsTotal prometheus.Counter

	// Kafka metrics
	KafkaMessagesSent prometheus.Counter
	KafkaErrorsTotal  prometheus.Counter

	// Rate limiting metrics
	RateLimitHitsTotal prometheus.Counter
}

// NewMetrics creates and registers all Prometheus metrics
func NewMetrics(namespace string) *Metrics {
	return &Metrics{
		HTTPRequestsTotal: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Namespace: namespace,
				Name:      "http_requests_total",
				Help:      "Total HTTP requests",
			},
			[]string{"method", "endpoint", "status"},
		),
		HTTPRequestDuration: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Namespace: namespace,
				Name:      "http_request_duration_seconds",
				Help:      "HTTP request duration",
				Buckets:   prometheus.DefBuckets,
			},
			[]string{"method", "endpoint"},
		),
		HTTPRequestsInFlight: promauto.NewGauge(
			prometheus.GaugeOpts{
				Namespace: namespace,
				Name:      "http_requests_in_flight",
				Help:      "HTTP requests in flight",
			},
		),
		OrdersCreatedTotal: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Namespace: namespace,
				Name:      "orders_created_total",
				Help:      "Total orders created",
			},
			[]string{"status"},
		),
		OrderValue: promauto.NewHistogram(
			prometheus.HistogramOpts{
				Namespace: namespace,
				Name:      "order_value_dollars",
				Help:      "Order value distribution",
				Buckets:   []float64{10, 50, 100, 200, 500, 1000, 5000},
			},
		),
		OrderItemsPerOrder: promauto.NewHistogram(
			prometheus.HistogramOpts{
				Namespace: namespace,
				Name:      "order_items_count",
				Help:      "Items per order",
				Buckets:   []float64{1, 2, 3, 5, 10, 20, 50},
			},
		),
		DBErrorsTotal: promauto.NewCounter(
			prometheus.CounterOpts{
				Namespace: namespace,
				Name:      "db_errors_total",
				Help:      "Database errors",
			},
		),
		CacheHitsTotal: promauto.NewCounter(
			prometheus.CounterOpts{
				Namespace: namespace,
				Name:      "cache_hits_total",
				Help:      "Cache hits",
			},
		),
		CacheMissesTotal: promauto.NewCounter(
			prometheus.CounterOpts{
				Namespace: namespace,
				Name:      "cache_misses_total",
				Help:      "Cache misses",
			},
		),
		CacheErrorsTotal: promauto.NewCounter(
			prometheus.CounterOpts{
				Namespace: namespace,
				Name:      "cache_errors_total",
				Help:      "Cache errors",
			},
		),
		KafkaMessagesSent: promauto.NewCounter(
			prometheus.CounterOpts{
				Namespace: namespace,
				Name:      "kafka_messages_sent_total",
				Help:      "Kafka messages sent",
			},
		),
		KafkaErrorsTotal: promauto.NewCounter(
			prometheus.CounterOpts{
				Namespace: namespace,
				Name:      "kafka_errors_total",
				Help:      "Kafka errors",
			},
		),
		RateLimitHitsTotal: promauto.NewCounter(
			prometheus.CounterOpts{
				Namespace: namespace,
				Name:      "rate_limit_hits_total",
				Help:      "Rate limit hits",
			},
		),
	}
}

// Middleware returns Gin middleware for recording HTTP metrics
func (m *Metrics) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.URL.Path == "/metrics" {
			c.Next()
			return
		}

		start := time.Now()
		m.HTTPRequestsInFlight.Inc()
		defer m.HTTPRequestsInFlight.Dec()

		c.Next()

		duration := time.Since(start).Seconds()
		status := strconv.Itoa(c.Writer.Status())

		m.HTTPRequestsTotal.WithLabelValues(
			c.Request.Method, c.FullPath(), status,
		).Inc()

		m.HTTPRequestDuration.WithLabelValues(
			c.Request.Method, c.FullPath(),
		).Observe(duration)
	}
}

// RecordOrderCreated records order creation metrics
func (m *Metrics) RecordOrderCreated(status string, value float64, itemCount int) {
	m.OrdersCreatedTotal.WithLabelValues(status).Inc()
	m.OrderValue.Observe(value)
	m.OrderItemsPerOrder.Observe(float64(itemCount))
}

// RecordCacheHit records a cache hit
func (m *Metrics) RecordCacheHit() {
	m.CacheHitsTotal.Inc()
}

// RecordCacheMiss records a cache miss
func (m *Metrics) RecordCacheMiss() {
	m.CacheMissesTotal.Inc()
}

// RecordCacheError records a cache error
func (m *Metrics) RecordCacheError() {
	m.CacheErrorsTotal.Inc()
}

// RecordDBError records a database error
func (m *Metrics) RecordDBError() {
	m.DBErrorsTotal.Inc()
}

// RecordKafkaMessage records a Kafka message
func (m *Metrics) RecordKafkaMessage() {
	m.KafkaMessagesSent.Inc()
}

// RecordKafkaError records a Kafka error
func (m *Metrics) RecordKafkaError() {
	m.KafkaErrorsTotal.Inc()
}

// RecordRateLimitHit records a rate limit hit
func (m *Metrics) RecordRateLimitHit() {
	m.RateLimitHitsTotal.Inc()
}