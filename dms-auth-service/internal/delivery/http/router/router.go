package router

import (
"github.com/nextdms/authservice/configs"
"github.com/nextdms/authservice/internal/delivery/http/handler"
"github.com/nextdms/authservice/internal/delivery/http/middleware"
"github.com/nextdms/authservice/internal/domain/repository"
"github.com/nextdms/authservice/internal/infrastructure/jwt"
"time"

"github.com/gin-gonic/gin"
)

func Setup(
cfg *configs.Config,
authHandler *handler.AuthHandler,
rateLimiterRepo repository.RateLimiterRepository,
blacklistRepo repository.TokenBlacklistRepository,
jwtService *jwt.JWTService,
) *gin.Engine {
gin.SetMode(cfg.Server.Mode)
r := gin.New()
r.Use(gin.Recovery(), gin.Logger())

// Health check
r.GET("/health", func(c *gin.Context) {
c.JSON(200, gin.H{"status": "ok", "time": time.Now()})
})

// API v1
api := r.Group("/api/v1")
{
// Public auth routes - apply rate limiter
auth := api.Group("/auth")
auth.Use(middleware.RateLimiter(rateLimiterRepo, 20, 60)) // 20 reqs/min per IP
{
auth.POST("/login", authHandler.Login)
auth.POST("/refresh", authHandler.RefreshToken)
// Forgot password - stricter rate limit (5 req/min)
auth.POST("/forgot-password", middleware.RateLimiter(rateLimiterRepo, 5, 60), authHandler.ForgotPassword)
auth.POST("/reset-password", middleware.RateLimiter(rateLimiterRepo, 10, 60), authHandler.ResetPassword)
}

// Protected routes - require JWT
protected := api.Group("/auth")
protected.Use(middleware.JWTAuth(jwtService, blacklistRepo))
{
protected.POST("/logout", authHandler.Logout)
protected.GET("/me", authHandler.Me)
}
}

return r
}
