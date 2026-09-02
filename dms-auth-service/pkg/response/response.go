package response

import (
	"github.com/nextdms/authservice/pkg/errors"
	"github.com/gin-gonic/gin"
)

type Response struct {
	Success bool        `json:"success"`
	Code    string     `json:"code,omitempty"`
	Message string     `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   *ErrorInfo `json:"error,omitempty"`
}

type ErrorInfo struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

func Success(c *gin.Context, data interface{}) {
	c.JSON(200, Response{
		Success: true,
		Data:    data,
	})
}

func Created(c *gin.Context, data interface{}) {
	c.JSON(201, Response{
		Success: true,
		Data:    data,
	})
}

func Error(c *gin.Context, err error) {
	if appErr, ok := err.(*errors.AppError); ok {
		c.JSON(appErr.HTTPStatus, Response{
			Success: false,
			Code:    appErr.Code,
			Message: appErr.Message,
			Error: &ErrorInfo{
				Code:    appErr.Code,
				Message: appErr.Message,
				Details: appErr.Details,
			},
		})
		return
	}
	c.JSON(500, Response{
		Success: false,
		Code:    "INTERNAL_ERROR",
		Message: "Lỗi hệ thống",
		Error: &ErrorInfo{
			Code:    "INTERNAL_ERROR",
			Message: "Lỗi hệ thống",
		},
	})
}

func BadRequest(c *gin.Context, message string) {
	c.JSON(400, Response{
		Success: false,
		Code:    "BAD_REQUEST",
		Message: message,
		Error: &ErrorInfo{
			Code:    "BAD_REQUEST",
			Message: message,
		},
	})
}

func Unauthorized(c *gin.Context, message string) {
	c.JSON(401, Response{
		Success: false,
		Code:    "UNAUTHORIZED",
		Message: message,
		Error: &ErrorInfo{
			Code:    "UNAUTHORIZED",
			Message: message,
		},
	})
}
