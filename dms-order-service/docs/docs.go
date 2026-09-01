// Package docs DMS Order Service API Documentation
//
// DMS Order Service - FMCG Distribution Management System
//
// This service handles order processing for the DMS system with support for:
//   - Order creation and validation
//   - Real-time stock checking via Redis
//   - Async order publishing via Kafka
//   - Rate limiting per salesman
//   - Prometheus metrics
//
//	Schemes: http, https
//	BasePath: /api/v1
//	Version: 1.0.0
//	Host: localhost:8080
//
//	Consumes:
//	- application/json
//
//	Produces:
//	- application/json
//
//	Security:
//	- bearer
//
//	SecurityDefinitions:
//	bearer:
//	     type: apiKey
//	     name: Authorization
//	     in: header
//
// swagger:meta
package docs

import "dms-order-service/internal/domain/order"

// swagger:response orderResponse
type orderResponse struct {
	// in:body
	Body struct {
		// Order ID
		ID string `json:"id"`
		// Order status
		Status string `json:"status"`
		// Order message
		Message string `json:"message"`
	}
}

// swagger:response errorResponse
type errorResponse struct {
	// in:body
	Body struct {
		// Error code
		Code string `json:"code"`
		// Error message
		Message string `json:"message"`
		// Error details
		Details interface{} `json:"details,omitempty"`
	}
}

// swagger:response healthResponse
type healthResponse struct {
	// in:body
	Body struct {
		// Service name
		Service string `json:"service"`
		// Service version
		Version string `json:"version"`
		// Health status
		Status string `json:"status"`
		// Timestamp
		Timestamp string `json:"timestamp"`
		// Dependencies status
		Dependencies map[string]string `json:"dependencies,omitempty"`
	}
}

// swagger:response metricsResponse
type metricsResponse struct {
	// in:body
	Body string
}

// swagger:route GET /healthz health getHealth
// Returns the health status of the service.
// Responses:
//   200: healthResponse
//   503: errorResponse

// swagger:route GET /readyz health getReadiness
// Returns the readiness status of the service.
// Responses:
//   200: healthResponse
//   503: errorResponse

// swagger:route POST /api/v1/orders orders createOrder
// Creates a new order.
// Responses:
//   201: orderResponse
//   400: errorResponse
//   422: errorResponse
//   429: errorResponse
//   500: errorResponse

// swagger:route GET /api/v1/orders/{id} orders getOrder
// Gets an order by ID.
// Responses:
//   200: orderResponse
//   404: errorResponse
//   500: errorResponse

// swagger:route GET /metrics metrics getMetrics
// Returns Prometheus metrics.
// Responses:
//   200: metricsResponse

// Order request body
// swagger:model
type CreateOrderRequest struct {
	// Salesman ID
	// required: true
	// example: SM001
	SalesmanID string `json:"salesman_id" binding:"required"`
	// Outlet ID
	// required: true
	// example: OUT001
	OutletID string `json:"outlet_id" binding:"required"`
	// Order items
	// required: true
	Items []order.OrderItem `json:"items" binding:"required,dive"`
	// Notes
	// example: Please deliver before 5 PM
	Notes string `json:"notes,omitempty"`
}

// Order response
// swagger:model
type OrderResponse struct {
	// Order ID
	// example: ord_1234567890
	ID string `json:"id"`
	// Salesman ID
	// example: SM001
	SalesmanID string `json:"salesman_id"`
	// Outlet ID
	// example: OUT001
	OutletID string `json:"outlet_id"`
	// Order status
	// example: pending
	Status string `json:"status"`
	// Order items
	Items []order.OrderItem `json:"items"`
	// Total amount
	// example: 150000
	TotalAmount float64 `json:"total_amount"`
	// Notes
	Notes string `json:"notes,omitempty"`
	// Created at timestamp
	CreatedAt string `json:"created_at"`
	// Updated at timestamp
	UpdatedAt string `json:"updated_at,omitempty"`
}