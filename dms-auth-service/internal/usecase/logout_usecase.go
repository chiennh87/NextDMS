package usecase

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"time"

	"github.com/nextdms/authservice/internal/domain/entity"
	"github.com/nextdms/authservice/internal/domain/repository"
	)

type LogoutUseCase struct {
	sessionRepo    repository.SessionRepository
	blacklistRepo  repository.TokenBlacklistRepository
	auditPublisher repository.AuditEventPublisher
}

func NewLogoutUseCase(
	sessionRepo repository.SessionRepository,
	blacklistRepo repository.TokenBlacklistRepository,
	auditPublisher repository.AuditEventPublisher,
) *LogoutUseCase {
	return &LogoutUseCase{
		sessionRepo:    sessionRepo,
		blacklistRepo: blacklistRepo,
		auditPublisher: auditPublisher,
	}
}

type LogoutInput struct {
	UserID         string
	AccessToken    string
	AccessTokenExp int64
	RefreshToken   string
	IPAddress      string
	AllDevices     bool // logout all devices
}

func (uc *LogoutUseCase) Execute(ctx context.Context, input LogoutInput) error {
	// 1. Delete refresh token from Redis
	if input.RefreshToken != "" {
		if err := uc.sessionRepo.Delete(ctx, input.RefreshToken); err != nil {
			// Log but don't fail - refresh token might already be expired
		}
	}

	// 2. Blacklist access token until it expires
	if input.AccessToken != "" && input.AccessTokenExp > 0 {
		// Use token hash as key (don't store raw token)
		tokenHash := hashToken(input.AccessToken)
		ttl := input.AccessTokenExp - time.Now().Unix()
		if ttl > 0 {
			if err := uc.blacklistRepo.Add(ctx, tokenHash, ttl); err != nil {
				// Log but don't fail
			}
		}
	}

	// 3. If AllDevices=true, delete all sessions for this user
	if input.AllDevices {
		if err := uc.sessionRepo.DeleteByUserID(ctx, input.UserID); err != nil {
			return err
		}
	}

	// 4. Publish audit event
	go func() {
		evt := &entity.AuditEvent{
			EventType: "USER_LOGGED_OUT",
			UserID:    input.UserID,
			IPAddress: input.IPAddress,
			Metadata: map[string]interface{}{
				"all_devices": input.AllDevices,
			},
			Timestamp: time.Now(),
		}
		uc.auditPublisher.Publish(context.Background(), evt)
	}()

	return nil
}

// hashToken creates SHA256 hash of token for storage
func hashToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}

