package redis

import (
	"context"
	"github.com/nextdms/authservice/configs"
	"github.com/nextdms/authservice/internal/domain/entity"
	"encoding/json"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

type RedisClient struct {
	client *redis.Client
}

func NewRedisClient(cfg configs.RedisConfig) (*RedisClient, error) {
	client := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", cfg.Host, cfg.Port),
		Password: cfg.Password,
		DB:       cfg.DB,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to connect to redis: %w", err)
	}

	return &RedisClient{client: client}, nil
}

func (r *RedisClient) Close() error { return r.client.Close() }
func (r *RedisClient) Client() *redis.Client { return r.client }

// ============ Session Repository ============

const sessionPrefix = "session:"
const sessionTTL = 7 * 24 * time.Hour // 7 days

type RedisSessionRepository struct {
	r *RedisClient
}

func NewRedisSessionRepository(r *RedisClient) *RedisSessionRepository {
	return &RedisSessionRepository{r: r}
}

func (repo *RedisSessionRepository) Create(ctx context.Context, session *entity.UserSession) error {
	key := sessionPrefix + session.RefreshToken
	data, err := json.Marshal(session)
	if err != nil {
		return fmt.Errorf("failed to marshal session: %w", err)
	}
	ttl := time.Until(session.ExpiresAt)
	if ttl < 0 {
		ttl = sessionTTL
	}
	return repo.r.client.Set(ctx, key, data, ttl).Err()
}

func (repo *RedisSessionRepository) FindByRefreshToken(ctx context.Context, refreshToken string) (*entity.UserSession, error) {
	key := sessionPrefix + refreshToken
	data, err := repo.r.client.Get(ctx, key).Bytes()
	if err == redis.Nil {
		return nil, nil // Session not found
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get session: %w", err)
	}

	var session entity.UserSession
	if err := json.Unmarshal(data, &session); err != nil {
		return nil, fmt.Errorf("failed to unmarshal session: %w", err)
	}
	return &session, nil
}

func (repo *RedisSessionRepository) Delete(ctx context.Context, refreshToken string) error {
	key := sessionPrefix + refreshToken
	return repo.r.client.Del(ctx, key).Err()
}

func (repo *RedisSessionRepository) DeleteByUserID(ctx context.Context, userID string) error {
	pattern := sessionPrefix + "*"
	var cursor uint64
	var keysToDelete []string

	for {
		var keys []string
		var err error
		keys, cursor, err = repo.r.client.Scan(ctx, cursor, pattern, 100).Result()
		if err != nil {
			return err
		}

		for _, key := range keys {
			data, err := repo.r.client.Get(ctx, key).Bytes()
			if err != nil {
				continue
			}
			var session entity.UserSession
			if json.Unmarshal(data, &session) == nil && session.UserID == userID {
				keysToDelete = append(keysToDelete, key)
			}
		}

		if cursor == 0 {
			break
		}
	}

	if len(keysToDelete) > 0 {
		return repo.r.client.Del(ctx, keysToDelete...).Err()
	}
	return nil
}

// ============ Rate Limiter (Sliding Window) ============

const rateLimitPrefix = "ratelimit:"

type RedisRateLimiterRepository struct {
	r *RedisClient
}

func NewRedisRateLimiterRepository(r *RedisClient) *RedisRateLimiterRepository {
	return &RedisRateLimiterRepository{r: r}
}

// Allow implements sliding window rate limiting
// Returns: allowed, remaining, resetAt (unix timestamp), error
func (repo *RedisRateLimiterRepository) Allow(ctx context.Context, key string, maxAttempts int, windowSec int) (bool, int, int64, error) {
	rateLimitKey := rateLimitPrefix + key
	now := time.Now()
	windowStart := now.Add(-time.Duration(windowSec) * time.Second)
	resetAt := now.Add(time.Duration(windowSec) * time.Second).Unix()

	// Use Redis sorted set with timestamps as scores
	pipe := repo.r.client.Pipeline()

	// Remove old entries outside the window
	pipe.ZRemRangeByScore(ctx, rateLimitKey, "0", fmt.Sprintf("%d", windowStart.UnixNano()))

	// Count current entries in window
	countCmd := pipe.ZCard(ctx, rateLimitKey)

	// Add current request
	pipe.ZAdd(ctx, rateLimitKey, redis.Z{Score: float64(now.UnixNano()), Member: fmt.Sprintf("%d", now.UnixNano())})

	// Set expiry
	pipe.Expire(ctx, rateLimitKey, time.Duration(windowSec)*time.Second)

	_, err := pipe.Exec(ctx)
	if err != nil {
		return false, 0, 0, err
	}

	count := int(countCmd.Val())
	remaining := maxAttempts - count - 1
	if remaining < 0 {
		remaining = 0
	}

	allowed := count < maxAttempts
	return allowed, remaining, resetAt, nil
}

func (repo *RedisRateLimiterRepository) Reset(ctx context.Context, key string) error {
	rateLimitKey := rateLimitPrefix + key
	return repo.r.client.Del(ctx, rateLimitKey).Err()
}

// =================== Token Blacklist ===================

const blacklistPrefix = "token_blacklist:"

type RedisTokenBlacklistRepository struct {
r *RedisClient
}

func NewRedisTokenBlacklistRepository(r *RedisClient) *RedisTokenBlacklistRepository {
return &RedisTokenBlacklistRepository{r: r}
}

func (repo *RedisTokenBlacklistRepository) Add(ctx context.Context, tokenSignature string, ttlSeconds int64) error {
if ttlSeconds <= 0 { return nil }
key := blacklistPrefix + tokenSignature
return repo.r.client.Set(ctx, key, "1", time.Duration(ttlSeconds)*time.Second).Err()
}

func (repo *RedisTokenBlacklistRepository) IsBlacklisted(ctx context.Context, tokenSignature string) (bool, error) {
key := blacklistPrefix + tokenSignature
n, err := repo.r.client.Exists(ctx, key).Result()
if err != nil { return false, err }
return n > 0, nil
}

// =================== OTP Store ===================

const otpPrefix = "otp:forgot_pw:"
const otpResendPrefix = "otp:forgot_pw:resend:"

type RedisOTPRepository struct {
r *RedisClient
}

func NewRedisOTPRepository(r *RedisClient) *RedisOTPRepository {
return &RedisOTPRepository{r: r}
}

func (repo *RedisOTPRepository) Save(ctx context.Context, email string, otp string, ttl time.Duration) error {
key := otpPrefix + email
return repo.r.client.Set(ctx, key, otp, ttl).Err()
}

func (repo *RedisOTPRepository) Get(ctx context.Context, email string) (string, error) {
key := otpPrefix + email
v, err := repo.r.client.Get(ctx, key).Result()
if err == redis.Nil { return "", nil }
if err != nil { return "", err }
return v, nil
}

func (repo *RedisOTPRepository) Delete(ctx context.Context, email string) error {
key := otpPrefix + email
return repo.r.client.Del(ctx, key).Err()
}

func (repo *RedisOTPRepository) SetResendCooldown(ctx context.Context, email string, ttl time.Duration) error {
key := otpResendPrefix + email
return repo.r.client.Set(ctx, key, "1", ttl).Err()
}

func (repo *RedisOTPRepository) IsInResendCooldown(ctx context.Context, email string) (bool, error) {
key := otpResendPrefix + email
n, err := repo.r.client.Exists(ctx, key).Result()
if err != nil { return false, err }
return n > 0, nil
}
