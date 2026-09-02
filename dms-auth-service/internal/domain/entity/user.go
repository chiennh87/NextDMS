package entity

import "time"

type User struct {
	ID           string    `json:"id"`
	Username     string    `json:"username"`
	Phone        string    `json:"phone"`
	Email        string    `json:"email,omitempty"`
	PasswordHash string    `json:"-"`
	FullName     string    `json:"full_name"`
	EmployeeCode string    `json:"employee_code"`
	RoleID       string    `json:"role_id"`
	IsActive     bool      `json:"is_active"`
	FailedLogins int       `json:"-"`
	LockedUntil  *time.Time `json:"-"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type Role struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Permissions []string `json:"permissions"` // e.g. ["order:create", "order:read", "checkin:create"]
}

type UserSession struct {
	UserID       string    `json:"user_id"`
	RefreshToken string    `json:"refresh_token"`
	DeviceID     string    `json:"device_id"`
	DeviceName   string    `json:"device_name"`
	IPAddress    string    `json:"ip_address"`
	ExpiresAt    time.Time `json:"expires_at"`
	CreatedAt    time.Time `json:"created_at"`
}

type LoginResult struct {
	User           *User         `json:"user"`
	AccessToken    string        `json:"access_token"`
	RefreshToken   string        `json:"refresh_token"`
	TokenType      string        `json:"token_type"` // "Bearer"
	ExpiresIn      int64         `json:"expires_in"` // seconds
	Permissions    []string      `json:"permissions"`
	Roles          []string      `json:"roles"`
	NeedSyncMaster bool          `json:"need_sync_master"`
	SessionInfo    *UserSession  `json:"session_info"`
}

type AuditEvent struct {
	EventType string                 `json:"event_type"` // "USER_LOGGED_IN", "LOGIN_FAILED", "LOGOUT"
	UserID    string                 `json:"user_id,omitempty"`
	Username  string                 `json:"username,omitempty"`
	IPAddress string                 `json:"ip_address"`
	DeviceID  string                 `json:"device_id,omitempty"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
	Timestamp time.Time              `json:"timestamp"`
}

// EmailEvent dùng cho email worker (Kafka hoặc in-process channel)
type EmailEvent struct {
	EventType string    `json:"event_type"` // "FORGOT_PASSWORD_OTP", "WELCOME", "PASSWORD_CHANGED"
	To        string    `json:"to"`
	Subject   string    `json:"subject"`
	Template  string    `json:"template"` // "forgot_password_otp"
	Data      EmailData `json:"data"`
	UserID    string    `json:"user_id,omitempty"`
	Timestamp time.Time `json:"timestamp"`
}

type EmailData struct {
	OTPCode      string `json:"otp_code,omitempty"`
	ResetLink    string `json:"reset_link,omitempty"`
	FullName     string `json:"full_name,omitempty"`
	ExpiresInMin int    `json:"expires_in_min,omitempty"`
	IPAddress    string `json:"ip_address,omitempty"`
}
