package dto

import "github.com/go-playground/validator/v10"

type LoginRequest struct {
	Username   string `json:"username" validate:"required,min=3,max=50"`
	Password   string `json:"password" validate:"required,min=6,max=100"`
	DeviceID   string `json:"device_id" validate:"required"`
	DeviceName string `json:"device_name"`
	AppVersion string `json:"app_version"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required,uuid4"`
	DeviceID     string `json:"device_id" validate:"required"`
}

type LogoutRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required,uuid4"`
	DeviceID     string `json:"device_id"`
}

type LoginResponse struct {
	User           *UserDTO `json:"user"`
	AccessToken    string   `json:"access_token"`
	RefreshToken   string   `json:"refresh_token"`
	TokenType      string   `json:"token_type"`
	ExpiresIn      int64    `json:"expires_in"`
	Permissions    []string `json:"permissions"`
	Roles          []string `json:"roles"`
	NeedSyncMaster bool     `json:"need_sync_master"`
}

type UserDTO struct {
	ID           string `json:"id"`
	Username     string `json:"username"`
	Phone        string `json:"phone"`
	Email        string `json:"email,omitempty"`
	FullName     string `json:"full_name"`
	EmployeeCode string `json:"employee_code"`
	RoleID       string `json:"role_id"`
	IsActive     bool   `json:"is_active"`
}

type ErrorResponse struct {
	Success bool       `json:"success"`
	Code    string     `json:"code"`
	Message string     `json:"message"`
	Error   *ErrorInfo `json:"error,omitempty"`
}

type ErrorInfo struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

func (r *LoginRequest) Validate() error {
	return validator.New().Struct(r)
}

func (r *RefreshRequest) Validate() error {
	return validator.New().Struct(r)
}

func (r *LogoutRequest) Validate() error {
	return validator.New().Struct(r)
}

// Forgot Password DTOs
type ForgotPasswordRequest struct {
        Email string `json:"email" validate:"required,email"`
}

type ForgotPasswordResponse struct {
        Success   bool `json:"success"`
        Message   string `json:"message"`
        ExpiresIn int  `json:"expires_in"`
}

type ResetPasswordRequest struct {
        Email       string `json:"email" validate:"required,email"`
        OTP         string `json:"otp" validate:"required,len=6"`
        NewPassword string `json:"new_password" validate:"required,min=8,max=100"`
}

type ResetPasswordResponse struct {
        Success        bool   `json:"success"`
        Message        string `json:"message"`
        SessionsRevoked int   `json:"sessions_revoked"`
}

func (r *ForgotPasswordRequest) Validate() error {
        return validator.New().Struct(r)
}

func (r *ResetPasswordRequest) Validate() error {
        return validator.New().Struct(r)
}
