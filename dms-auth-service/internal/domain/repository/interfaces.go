package repository

import (
"context"
"github.com/nextdms/authservice/internal/domain/entity"
)

type UserRepository interface {
FindByUsername(ctx context.Context, username string) (*entity.User, error)
FindByID(ctx context.Context, id string) (*entity.User, error)
IncrementFailedLogins(ctx context.Context, userID string) error
ResetFailedLogins(ctx context.Context, userID string) error
LockAccount(ctx context.Context, userID string, lockedUntil interface{}) error
GetUserPermissions(ctx context.Context, userID string) ([]string, error)
GetUserRoles(ctx context.Context, userID string) ([]string, error)
NeedMasterDataSync(ctx context.Context, userID string) (bool, error)
GetLastMasterDataVersion(ctx context.Context, userID string) (string, error)
FindByEmail(ctx context.Context, email string) (*entity.User, error)
UpdatePassword(ctx context.Context, userID string, passwordHash string) error
}

type SessionRepository interface {
Create(ctx context.Context, session *entity.UserSession) error
FindByRefreshToken(ctx context.Context, refreshToken string) (*entity.UserSession, error)
Delete(ctx context.Context, refreshToken string) error
DeleteByUserID(ctx context.Context, userID string) error
}

type RateLimiterRepository interface {
Allow(ctx context.Context, key string, maxAttempts int, windowSec int) (bool, int, int64, error)
Reset(ctx context.Context, key string) error
}

type AuditEventPublisher interface {
Publish(ctx context.Context, event *entity.AuditEvent) error
}

type TokenBlacklistRepository interface {
Add(ctx context.Context, tokenSignature string, ttlSeconds int64) error
IsBlacklisted(ctx context.Context, tokenSignature string) (bool, error)
}

type EmailPublisher interface {
PublishEmail(ctx context.Context, event *entity.EmailEvent) error
}
