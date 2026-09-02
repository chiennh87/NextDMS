package v1

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"

	domainorder "dms-order-service/internal/domain/order"
	orderusecase "dms-order-service/internal/usecase/order"
)

// OrderHandler xử lý các request đối với endpoint /api/v1/orders.
// Sử dụng Gin framework cho tốc độ cao và support CORS, middleware tốt.
type OrderHandler struct {
	useCase  orderusecase.UseCase
	validate *validator.Validate
}

// NewOrderHandler khởi tạo handler với UseCase và validator.
func NewOrderHandler(u orderusecase.UseCase) *OrderHandler {
	return &OrderHandler{
		useCase:  u,
		validate: validator.New(),
	}
}

// CreateOrder handles POST /api/v1/orders
// - Validate đầu vào (SalesmanID, OutletID, Items).
// - Gọi UseCase kiểm tra tồn kho, lưu DB, gửi Kafka event.
// - Map lỗi nghiệp vụ sang đúng HTTP status.
func (h *OrderHandler) CreateOrder(c *gin.Context) {
	var input orderusecase.CreateOrderInput

	// 1. Bind và validate JSON body
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":  "Dữ liệu đầu vào không hợp lệ",
			"detail": err.Error(),
		})
		return
	}

	// 2. Validate struct tags (gin không tự động validate tag "validate")
	if err := h.validate.Struct(input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":  "Dữ liệu đầu vào không hợp lệ",
			"detail": formatValidationErrors(err),
		})
		return
	}

	// 3. Gọi UseCase tạo đơn hàng (kiểm tra tồn kho Redis, lưu Postgres, publish Kafka)
	result, err := h.useCase.CreateOrder(c.Request.Context(), input)
	if err != nil {
		h.handleUseCaseError(c, err)
		return
	}

	// 4. Trả về kết quả thành công (Status 201 Created)
	c.JSON(http.StatusCreated, gin.H{
		"message": "Đơn hàng đã được ghi nhận",
		"data": gin.H{
			"id":           result.ID,
			"order_number": result.OrderNumber,
			"status":       result.Status,
			"total_amount": result.TotalAmount,
			"final_amount": result.FinalAmount,
			"created_at":   result.CreatedAt,
		},
	})
}

// handleUseCaseError map lỗi nghiệp vụ sang đúng HTTP status.
// - OutOfStock -> 409 Conflict (khách hàng không đủ tồn kho).
// - Validation -> 400 Bad Request.
// - Các lỗi khác -> 500 Internal Server Error.
func (h *OrderHandler) handleUseCaseError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, domainorder.ErrOutOfStock):
		c.JSON(http.StatusConflict, gin.H{
			"error":  "Tồn kho không đủ",
			"detail": err.Error(),
		})
	case errors.Is(err, domainorder.ErrEmptyItems):
		c.JSON(http.StatusBadRequest, gin.H{
			"error":  "Dữ liệu không hợp lệ",
			"detail": err.Error(),
		})
	default:
		// Log chi tiết lỗi server (Internal error) cho team giám sát.
		// Trả về thông báo nhẹ nhàng cho Salesman (không expos thông tin DB).
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":  "Không thể tạo đơn hàng. Vui lòng thử lại sau.",
			"detail": err.Error(), // Có thể bỏ đi sau deployment, giữ cho debugging QA.
		})
	}
}

// formatValidationErrors chuyển slice lỗi validation sang chuỗi ngắn gọn.
func formatValidationErrors(err error) string {
	if errs, ok := err.(validator.ValidationErrors); ok {
		var msg string
		for i, e := range errs {
			if i > 0 {
				msg += ", "
			}
			msg += e.Field() + " không hợp lệ"
		}
		return msg
	}
	return err.Error()
}
