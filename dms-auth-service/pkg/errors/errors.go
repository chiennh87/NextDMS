package errors

import (
stderrors "errors"
"fmt"
"net/http"
)

var (
ErrInvalidCredentials = New("INVALID_CREDENTIALS", "Username or password incorrect", http.StatusUnauthorized)
ErrUserNotFound       = New("USER_NOT_FOUND", "User not found", http.StatusNotFound)
ErrInvalidToken       = New("INVALID_TOKEN", "Invalid or expired token", http.StatusUnauthorized)
ErrTokenExpired       = New("TOKEN_EXPIRED", "Token expired", http.StatusUnauthorized)
ErrTokenRevoked       = New("TOKEN_REVOKED", "Token has been revoked", http.StatusUnauthorized)
ErrAccountLocked      = New("ACCOUNT_LOCKED", "Account is locked", http.StatusForbidden)
ErrAccountInactive    = New("ACCOUNT_INACTIVE", "Account is inactive", http.StatusForbidden)
ErrInvalidRequest     = New("INVALID_REQUEST", "Invalid request", http.StatusBadRequest)
ErrInternalServer     = New("INTERNAL_ERROR", "Internal server error", http.StatusInternalServerError)
)

type AppError struct {
Code       string `json:"code"`
Message    string `json:"message"`
HTTPStatus int    `json:"-"`
Details    string `json:"details,omitempty"`
}

func (e *AppError) Error() string {
if e.Details != "" {
return fmt.Sprintf("%s: %s (%s)", e.Code, e.Message, e.Details)
}
return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

func New(code, message string, httpStatus int) *AppError {
return &AppError{Code: code, Message: message, HTTPStatus: httpStatus}
}

func NewWithDetails(code, message, details string, httpStatus int) *AppError {
return &AppError{Code: code, Message: message, HTTPStatus: httpStatus, Details: details}
}

func IsAppError(err error) bool {
var appErr *AppError
return stderrors.As(err, &appErr)
}

func AsAppError(err error) *AppError {
var appErr *AppError
if stderrors.As(err, &appErr) {
return appErr
}
return ErrInternalServer
}

func Wrap(err error, details string) error {
appErr := AsAppError(err)
appErr.Details = details
return appErr
}
