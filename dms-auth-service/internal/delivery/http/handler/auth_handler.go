package handler

import (
"strings"
"time"

"github.com/nextdms/authservice/configs"
"github.com/nextdms/authservice/internal/delivery/http/dto"
"github.com/nextdms/authservice/internal/usecase"
"github.com/nextdms/authservice/pkg/response"
"github.com/gin-gonic/gin"
)

type AuthHandler struct {
loginUseCase        *usecase.LoginUseCase
logoutUseCase       *usecase.LogoutUseCase
forgotPasswordUC    *usecase.ForgotPasswordUseCase
jwtAccessExpirySecs int64
}

func NewAuthHandler(
loginUC *usecase.LoginUseCase,
logoutUC *usecase.LogoutUseCase,
forgotUC *usecase.ForgotPasswordUseCase,
cfg *configs.Config,
) *AuthHandler {
// Parse JWT expiry for logout blacklist TTL
var expirySecs int64 = 900
if d, err := time.ParseDuration(cfg.JWT.AccessTokenExpiry); err == nil {
expirySecs = int64(d.Seconds())
}
return &AuthHandler{
loginUseCase:        loginUC,
logoutUseCase:       logoutUC,
forgotPasswordUC:    forgotUC,
jwtAccessExpirySecs: expirySecs,
}
}

// Login handles POST /api/v1/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
var req dto.LoginRequest
if err := c.ShouldBindJSON(&req); err != nil {
response.BadRequest(c, "Invalid request body: "+err.Error())
return
}
if err := req.Validate(); err != nil {
response.BadRequest(c, "Validation failed: "+err.Error())
return
}
clientIP := c.ClientIP()
result, err := h.loginUseCase.Execute(c.Request.Context(), usecase.LoginInput{
Username: req.Username, Password: req.Password, DeviceID: req.DeviceID,
DeviceName: req.DeviceName, IPAddress: clientIP, AppVersion: req.AppVersion,
})
if err != nil {
response.Error(c, err)
return
}
loginResp := dto.LoginResponse{
User: &dto.UserDTO{
ID: result.User.ID, Username: result.User.Username, Phone: result.User.Phone,
Email: result.User.Email, FullName: result.User.FullName,
EmployeeCode: result.User.EmployeeCode, RoleID: result.User.RoleID, IsActive: result.User.IsActive,
},
AccessToken: result.AccessToken, RefreshToken: result.RefreshToken,
TokenType: result.TokenType, ExpiresIn: result.ExpiresIn,
Permissions: result.Permissions, Roles: result.Roles, NeedSyncMaster: result.NeedSyncMaster,
}
response.Success(c, loginResp)
}

// Logout handles POST /api/v1/auth/logout
func (h *AuthHandler) Logout(c *gin.Context) {
var req dto.LogoutRequest
if err := c.ShouldBindJSON(&req); err != nil {
response.BadRequest(c, "Invalid request body")
return
}
if err := req.Validate(); err != nil {
response.BadRequest(c, "Validation failed: "+err.Error())
return
}
authHeader := c.GetHeader("Authorization")
accessToken := strings.TrimPrefix(authHeader, "Bearer ")
userID, _ := c.Get("user_id")
userIDStr, _ := userID.(string)
allDevices := c.Query("all") == "true"
exp := h.jwtAccessExpirySecs
if v, ok := c.Get("token_exp"); ok {
if e, ok := v.(int64); ok {
exp = e
}
}
input := usecase.LogoutInput{
UserID: userIDStr, AccessToken: accessToken, AccessTokenExp: exp,
RefreshToken: req.RefreshToken, IPAddress: c.ClientIP(), AllDevices: allDevices,
}
if err := h.logoutUseCase.Execute(c.Request.Context(), input); err != nil {
response.Error(c, err)
return
}
response.Success(c, gin.H{"message": "Logged out successfully", "all_devices": allDevices})
}

// ForgotPassword handles POST /api/v1/auth/forgot-password
func (h *AuthHandler) ForgotPassword(c *gin.Context) {
var req dto.ForgotPasswordRequest
if err := c.ShouldBindJSON(&req); err != nil {
response.BadRequest(c, "Invalid request body")
return
}
if err := req.Validate(); err != nil {
response.BadRequest(c, "Validation failed: "+err.Error())
return
}
err := h.forgotPasswordUC.RequestOTP(c.Request.Context(), usecase.ForgotPasswordInput{
Email: req.Email, IPAddress: c.ClientIP(),
})
if err != nil {
response.Error(c, err)
return
}
response.Success(c, dto.ForgotPasswordResponse{
Success: true, Message: "Nếu email tồn tại, mã OTP đã được gửi đến hộp thư của bạn", ExpiresIn: 300,
})
}

// ResetPassword handles POST /api/v1/auth/reset-password
func (h *AuthHandler) ResetPassword(c *gin.Context) {
var req dto.ResetPasswordRequest
if err := c.ShouldBindJSON(&req); err != nil {
response.BadRequest(c, "Invalid request body")
return
}
if err := req.Validate(); err != nil {
response.BadRequest(c, "Validation failed: "+err.Error())
return
}
err := h.forgotPasswordUC.ResetPassword(c.Request.Context(), usecase.ResetPasswordInput{
Email: req.Email, OTP: req.OTP, NewPassword: req.NewPassword, IPAddress: c.ClientIP(),
})
if err != nil {
response.Error(c, err)
return
}
response.Success(c, dto.ResetPasswordResponse{Success: true, Message: "Mật khẩu đã được đặt lại thành công", SessionsRevoked: -1})
}

// Me handles GET /api/v1/auth/me
func (h *AuthHandler) Me(c *gin.Context) {
userID, exists := c.Get("user_id")
if !exists {
response.Unauthorized(c, "Unauthorized")
return
}
response.Success(c, gin.H{"user_id": userID})
}

// RefreshToken handles POST /api/v1/auth/refresh
func (h *AuthHandler) RefreshToken(c *gin.Context) {
        var req dto.RefreshRequest
        if err := c.ShouldBindJSON(&req); err != nil {
                response.BadRequest(c, "Invalid request body")
                return
        }
        if err := req.Validate(); err != nil {
                response.BadRequest(c, "Validation failed: "+err.Error())
                return
        }
        response.Success(c, gin.H{"message": "Not implemented yet"})
}
