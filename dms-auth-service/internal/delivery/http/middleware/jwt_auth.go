package middleware

import (
"crypto/sha256"
"encoding/hex"
"strings"

"github.com/nextdms/authservice/internal/domain/repository"
"github.com/nextdms/authservice/internal/infrastructure/jwt"
"github.com/nextdms/authservice/pkg/errors"
"github.com/nextdms/authservice/pkg/response"
"github.com/gin-gonic/gin"
)

// JWTAuth middleware - xác thực JWT token và kiểm tra blacklist
func JWTAuth(jwtService *jwt.JWTService, blacklistRepo repository.TokenBlacklistRepository) gin.HandlerFunc {
return func(c *gin.Context) {
authHeader := c.GetHeader("Authorization")
if authHeader == "" {
response.Unauthorized(c, "Missing Authorization header")
c.Abort()
return
}

parts := strings.SplitN(authHeader, " ", 2)
if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
response.Unauthorized(c, "Invalid Authorization header format")
c.Abort()
return
}

tokenString := parts[1]

// Check blacklist
if blacklistRepo != nil {
tokenHash := sha256Hash(tokenString)
blacklisted, _ := blacklistRepo.IsBlacklisted(c.Request.Context(), tokenHash)
if blacklisted {
response.Error(c, errors.ErrTokenRevoked)
c.Abort()
return
}
}

claims, err := jwtService.Verify(tokenString)
if err != nil {
if strings.Contains(err.Error(), "token is expired") {
response.Error(c, errors.ErrTokenExpired)
} else {
response.Error(c, errors.ErrInvalidToken)
}
c.Abort()
return
}

// Set user info in context
c.Set("user_id", claims.UserID)
c.Set("username", claims.Username)
c.Set("role", claims.Role)
c.Set("permissions", claims.Permissions)
c.Set("device_id", claims.DeviceID)
c.Set("token_exp", claims.ExpiresAt.Unix())

c.Next()
}
}

func sha256Hash(s string) string {
h := sha256.Sum256([]byte(s))
return hex.EncodeToString(h[:])
}

// RequirePermission middleware
func RequirePermission(requiredPermission string) gin.HandlerFunc {
return func(c *gin.Context) {
permissions, exists := c.Get("permissions")
if !exists {
response.Unauthorized(c, "No permissions found")
c.Abort()
return
}

perms, ok := permissions.([]string)
if !ok {
response.Unauthorized(c, "Invalid permissions format")
c.Abort()
return
}

hasPermission := false
for _, p := range perms {
if p == requiredPermission || p == "*" {
hasPermission = true
break
}
}

if !hasPermission {
response.Error(c, &AppError{Code: "FORBIDDEN", Message: "Insufficient permissions"})
c.Abort()
return
}

c.Next()
}
}
