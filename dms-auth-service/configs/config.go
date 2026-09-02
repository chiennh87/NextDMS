package configs

import (
"os"
"time"
)

type Config struct {
Server         ServerConfig
Database       DatabaseConfig
Redis          RedisConfig
Kafka          KafkaConfig
JWT            JWTConfig
RateLimit      RateLimitConfig
SMTP           SMTPConfig
ForgotPassword ForgotPasswordConfig
}

type ServerConfig struct {
Port string
Mode string
}

type DatabaseConfig struct {
Host            string
Port            string
User            string
Password        string
DBName          string
MaxConns        int
MinConns        int
MaxConnLifetime string
}

type RedisConfig struct {
Host     string
Port     string
Password string
DB       int
}

type KafkaConfig struct {
Brokers []string
Topic   string
}

type JWTConfig struct {
AccessTokenSecret  string
AccessTokenExpiry  string
RefreshTokenExpiry string
Issuer             string
}

type RateLimitConfig struct {
MaxAttempts int
WindowSec   int
}

type SMTPConfig struct {
Host     string
Port     int
Username string
Password string
FromName string
FromAddr string
UseTLS   bool
}

type ForgotPasswordConfig struct {
OTPLength         int
OTPTTL            time.Duration
ResendCooldown    time.Duration
MaxAttemptsPerHr  int
WorkerConcurrency int
}

func Load() *Config {
return &Config{
Server: ServerConfig{
Port: getEnv("SERVER_PORT", "8080"),
Mode: getEnv("GIN_MODE", "release"),
},
Database: DatabaseConfig{
Host:            getEnv("DB_HOST", "localhost"),
Port:            getEnv("DB_PORT", "5432"),
User:            getEnv("DB_USER", "dms"),
Password:        getEnv("DB_PASSWORD", "dms_password"),
DBName:          getEnv("DB_NAME", "dms"),
MaxConns:        25,
MinConns:        5,
MaxConnLifetime: "1h",
},
Redis: RedisConfig{
Host:     getEnv("REDIS_HOST", "localhost"),
Port:     getEnv("REDIS_PORT", "6379"),
Password: getEnv("REDIS_PASSWORD", ""),
DB:       0,
},
Kafka: KafkaConfig{
Brokers: []string{getEnv("KAFKA_BROKERS", "localhost:9092")},
Topic:   getEnv("KAFKA_TOPIC", "dms.audit.v1"),
},
JWT: JWTConfig{
AccessTokenSecret:  getEnv("JWT_ACCESS_SECRET", "change-me-in-production"),
AccessTokenExpiry:  getEnv("JWT_ACCESS_EXPIRY", "15m"),
RefreshTokenExpiry: getEnv("JWT_REFRESH_EXPIRY", "168h"),
Issuer:             "dms-auth-service",
},
RateLimit: RateLimitConfig{
MaxAttempts: 5,
WindowSec:   60,
},
SMTP: SMTPConfig{
Host:     getEnv("SMTP_HOST", "smtp.gmail.com"),
Port:     587,
Username: getEnv("SMTP_USERNAME", ""),
Password: getEnv("SMTP_PASSWORD", ""),
FromName: getEnv("SMTP_FROM_NAME", "DMS Sales"),
FromAddr: getEnv("SMTP_FROM_ADDR", "noreply@dms.local"),
UseTLS:   true,
},
ForgotPassword: ForgotPasswordConfig{
OTPLength:         6,
OTPTTL:            5 * time.Minute,
ResendCooldown:    60 * time.Second,
MaxAttemptsPerHr:  5,
WorkerConcurrency: 3,
},
}
}

func getEnv(key, fallback string) string {
if val := os.Getenv(key); val != "" {
return val
}
return fallback
}
