package main

import (
"github.com/nextdms/authservice/configs"
"github.com/nextdms/authservice/internal/delivery/http/handler"
"github.com/nextdms/authservice/internal/delivery/http/router"
"github.com/nextdms/authservice/internal/infrastructure/database"
emailInfra "github.com/nextdms/authservice/internal/infrastructure/email"
"github.com/nextdms/authservice/internal/infrastructure/hasher"
"github.com/nextdms/authservice/internal/infrastructure/jwt"
kafkaInfra "github.com/nextdms/authservice/internal/infrastructure/kafka"
redisInfra "github.com/nextdms/authservice/internal/infrastructure/redis"
"github.com/nextdms/authservice/internal/usecase"
"log"
"os"
"os/signal"
"syscall"

"go.uber.org/zap"
)

func main() {
logger, _ := zap.NewProduction()
defer logger.Sync()
cfg := configs.Load()

// 1. Init infrastructure
pgDB, err := database.NewPostgresDB(cfg.Database)
if err != nil {
logger.Fatal("Failed to connect to PostgreSQL", zap.Error(err))
}
defer pgDB.Close()

redisClient, err := redisInfra.NewRedisClient(cfg.Redis)
if err != nil {
logger.Fatal("Failed to connect to Redis", zap.Error(err))
}
defer redisClient.Close()

kafkaProducer := kafkaInfra.NewProducer(cfg.Kafka)
defer kafkaProducer.Close()

// 2. Init email worker
smtpCfg := emailInfra.SMTPConfig{
Host:     cfg.SMTP.Host,
Port:     cfg.SMTP.Port,
Username: cfg.SMTP.Username,
Password: cfg.SMTP.Password,
FromName: cfg.SMTP.FromName,
FromAddr: cfg.SMTP.FromAddr,
UseTLS:   cfg.SMTP.UseTLS,
}
smtpClient := emailInfra.NewSMTPClient(smtpCfg, logger)
emailWorker := emailInfra.NewWorker(smtpClient, cfg.ForgotPassword.WorkerConcurrency, logger)
emailWorker.Start()
defer emailWorker.Stop()
emailPublisher := emailInfra.NewInProcessEmailPublisher(emailWorker.Channel(), logger)

// 3. Init repositories
userRepo := database.NewPostgresUserRepository(pgDB)
sessionRepo := redisInfra.NewRedisSessionRepository(redisClient)
rateLimiterRepo := redisInfra.NewRedisRateLimiterRepository(redisClient)
blacklistRepo := redisInfra.NewRedisTokenBlacklistRepository(redisClient)
otpRepo := redisInfra.NewRedisOTPRepository(redisClient)
auditPublisher := kafkaInfra.NewAuditEventPublisher(kafkaProducer)

// 4. Init services
jwtService := jwt.NewJWTService(cfg.JWT)
bcryptHasher := hasher.NewBcryptHasher()

// 5. Init use cases
loginUseCase := usecase.NewLoginUseCase(userRepo, sessionRepo, rateLimiterRepo, auditPublisher, jwtService, bcryptHasher, cfg)
logoutUseCase := usecase.NewLogoutUseCase(sessionRepo, blacklistRepo, auditPublisher)
forgotPwUseCase := usecase.NewForgotPasswordUseCase(userRepo, sessionRepo, otpRepo, emailPublisher, auditPublisher, bcryptHasher, cfg.ForgotPassword, logger)

// 6. Init handlers
authHandler := handler.NewAuthHandler(loginUseCase, logoutUseCase, forgotPwUseCase, cfg)

// 7. Setup router
r := router.Setup(cfg, authHandler, rateLimiterRepo, blacklistRepo, jwtService)

// 8. Run server
go func() {
log.Printf("Auth service starting on :%s", cfg.Server.Port)
if err := r.Run(":" + cfg.Server.Port); err != nil {
logger.Fatal("Failed to start server", zap.Error(err))
}
}()

// Graceful shutdown
quit := make(chan os.Signal, 1)
signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
<-quit
log.Println("Shutting down...")
}
