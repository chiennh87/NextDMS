package usecase

import (
	"context"
	"github.com/nextdms/authservice/configs"
	"github.com/nextdms/authservice/internal/domain/entity"
	"github.com/nextdms/authservice/internal/domain/repository"
	"github.com/nextdms/authservice/internal/infrastructure/jwt"
	"github.com/nextdms/authservice/pkg/errors"
"github.com/google/uuid"
	"time"
)

type LoginInput struct {
	Username   string
	Password   string
	DeviceID   string
	DeviceName string
	IPAddress  string
	AppVersion string
}

type LoginUseCase struct {
	userRepo       repository.UserRepository
	sessionRepo    repository.SessionRepository
	rateLimiter    repository.RateLimiterRepository
	auditPublisher repository.AuditEventPublisher
	jwtService     *jwt.JWTService
	hasher         PasswordHasher
	cfg            *configs.Config
}

type PasswordHasher interface { Hash(password string) (string, error); Verify(password, hash string) bool }

func NewLoginUseCase(ur repository.UserRepository, sr repository.SessionRepository,
	rl repository.RateLimiterRepository, ap repository.AuditEventPublisher,
	js *jwt.JWTService, h PasswordHasher, cfg *configs.Config) *LoginUseCase {
	return &LoginUseCase{userRepo: ur, sessionRepo: sr, rateLimiter: rl,
		auditPublisher: ap, jwtService: js, hasher: h, cfg: cfg}
}

func (uc *LoginUseCase) Execute(ctx context.Context, input LoginInput) (*entity.LoginResult, error) {
	// 1. Rate limit by IP
	ipKey := "login:ip:" + input.IPAddress
	allowed, _, resetAt, err := uc.rateLimiter.Allow(ctx, ipKey, uc.cfg.RateLimit.MaxAttempts, uc.cfg.RateLimit.WindowSec)
	if err == nil && !allowed {
		uc.publish(ctx, "LOGIN_RATE_LIMITED", "", input.Username, input.IPAddress, input.DeviceID,
			map[string]interface{}{"remaining": 0, "reset_at": resetAt})
		return nil, errors.NewWithDetails("RATE_LIMITED", "QuÃ¡ nhiá»u yÃªu cáº§u", time.Unix(resetAt, 0).Format(time.RFC3339), 429)
	}

	// 2. Rate limit by account
	accKey := "login:account:" + input.Username
	allowed, _, _, _ = uc.rateLimiter.Allow(ctx, accKey, uc.cfg.RateLimit.MaxAttempts, uc.cfg.RateLimit.WindowSec)
	if !allowed { return nil, errors.ErrAccountLocked }

	// 3. Find user
	user, err := uc.userRepo.FindByUsername(ctx, input.Username)
	if err != nil {
		uc.publish(ctx, "LOGIN_FAILED", "", input.Username, input.IPAddress, input.DeviceID, map[string]interface{}{"reason": "user_not_found"})
		return nil, errors.ErrInvalidCredentials
	}

	// 4-6. Check status, locked, verify password
	if !user.IsActive { uc.publish(ctx, "LOGIN_FAILED", user.ID, user.Username, input.IPAddress, "", map[string]interface{}{"reason": "inactive"}); return nil, errors.ErrAccountInactive }
	if user.LockedUntil != nil && time.Now().Before(*user.LockedUntil) { uc.publish(ctx, "LOGIN_FAILED", user.ID, user.Username, input.IPAddress, "", map[string]interface{}{"reason": "locked"}); return nil, errors.ErrAccountLocked }
	if !uc.hasher.Verify(input.Password, user.PasswordHash) {
		_ = uc.userRepo.IncrementFailedLogins(ctx, user.ID)
		uc.publish(ctx, "LOGIN_FAILED", user.ID, user.Username, input.IPAddress, input.DeviceID, map[string]interface{}{"reason": "wrong_password"})
		return nil, errors.ErrInvalidCredentials
	}

	// 7. Reset failed logins
	_ = uc.userRepo.ResetFailedLogins(ctx, user.ID)
	_ = uc.rateLimiter.Reset(ctx, accKey)

	// 8. Get permissions
	perms, _ := uc.userRepo.GetUserPermissions(ctx, user.ID)
	roles, _ := uc.userRepo.GetUserRoles(ctx, user.ID)

	// 9. Generate tokens
	at, expIn, _ := uc.jwtService.Generate(user.ID, user.Username, user.RoleID, perms, input.DeviceID)
	rt := NewUUID()
	refreshExpiry, _ := time.ParseDuration(uc.cfg.JWT.RefreshTokenExpiry)
	if refreshExpiry == 0 { refreshExpiry = 7 * 24 * time.Hour }
	session := &entity.UserSession{UserID: user.ID, RefreshToken: rt, DeviceID: input.DeviceID,
		DeviceName: input.DeviceName, IPAddress: input.IPAddress, ExpiresAt: time.Now().Add(refreshExpiry), CreatedAt: time.Now()}
	_ = uc.sessionRepo.Create(ctx, session)

	// 10. Check master data sync
	needSync, _ := uc.userRepo.NeedMasterDataSync(ctx, user.ID)

	// 11. Publish success
	uc.publish(ctx, "USER_LOGGED_IN", user.ID, user.Username, input.IPAddress, input.DeviceID,
		map[string]interface{}{"app_version": input.AppVersion, "device_name": input.DeviceName, "need_sync": needSync})

	return &entity.LoginResult{User: user, AccessToken: at, RefreshToken: rt, TokenType: "Bearer",
		ExpiresIn: expIn, Permissions: perms, Roles: roles, NeedSyncMaster: needSync, SessionInfo: session}, nil
}

func (uc *LoginUseCase) publish(ctx context.Context, eventType, userID, username, ip, deviceID string, meta map[string]interface{}) {
	go func() {
		bg, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = uc.auditPublisher.Publish(bg, &entity.AuditEvent{EventType: eventType, UserID: userID, Username: username, IPAddress: ip, DeviceID: deviceID, Metadata: meta, Timestamp: time.Now()})
	}()
}

func NewUUID() string { return uuid.New().String() }



