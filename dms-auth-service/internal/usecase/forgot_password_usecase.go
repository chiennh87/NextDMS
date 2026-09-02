package usecase

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"strings"
	"time"

	"github.com/nextdms/authservice/configs"
	"github.com/nextdms/authservice/internal/domain/entity"
	"github.com/nextdms/authservice/internal/domain/repository"
	"github.com/nextdms/authservice/pkg/errors"
	"go.uber.org/zap"
)

type redisOTPRepository interface {
	Save(ctx context.Context, email string, otp string, ttl time.Duration) error
	Get(ctx context.Context, email string) (string, error)
	Delete(ctx context.Context, email string) error
	SetResendCooldown(ctx context.Context, email string, ttl time.Duration) error
	IsInResendCooldown(ctx context.Context, email string) (bool, error)
}

type ForgotPasswordUseCase struct {
	userRepo       repository.UserRepository
	sessionRepo    repository.SessionRepository
	otpRepo        redisOTPRepository
	emailPublisher repository.EmailPublisher
	auditPublisher repository.AuditEventPublisher
	hasher         PasswordHasher
	cfg            configs.ForgotPasswordConfig
	logger         *zap.Logger
}

func NewForgotPasswordUseCase(
	userRepo repository.UserRepository,
	sessionRepo repository.SessionRepository,
	otpRepo redisOTPRepository,
	emailPublisher repository.EmailPublisher,
	auditPublisher repository.AuditEventPublisher,
	hasher PasswordHasher,
	cfg configs.ForgotPasswordConfig,
	logger *zap.Logger,
) *ForgotPasswordUseCase {
	return &ForgotPasswordUseCase{
		userRepo: userRepo, sessionRepo: sessionRepo, otpRepo: otpRepo,
		emailPublisher: emailPublisher, auditPublisher: auditPublisher,
		hasher: hasher, cfg: cfg, logger: logger,
	}
}

type ForgotPasswordInput struct {
	Email     string
	IPAddress string
}

func (uc *ForgotPasswordUseCase) RequestOTP(ctx context.Context, input ForgotPasswordInput) error {
	email := strings.ToLower(strings.TrimSpace(input.Email))
	if email == "" {
		return errors.New("INVALID_REQUEST", "Email is required", 400)
	}
	user, err := uc.userRepo.FindByEmail(ctx, email)
	if err != nil {
		uc.logger.Info("forgot password: email not found", zap.String("email", email))
		return nil // prevent enumeration
	}
	inCooldown, _ := uc.otpRepo.IsInResendCooldown(ctx, email)
	if inCooldown {
		return errors.New("RATE_LIMITED", "Vui lÃ²ng Ä‘á»£i trÆ°á»›c khi yÃªu cáº§u mÃ£ má»›i", 429)
	}
	otp, err := generateOTP(uc.cfg.OTPLength)
	if err != nil {
		return errors.Wrap(err, "failed to generate OTP")
	}
	if err := uc.otpRepo.Save(ctx, email, otp, uc.cfg.OTPTTL); err != nil {
		return errors.Wrap(err, "failed to save OTP")
	}
	uc.otpRepo.SetResendCooldown(ctx, email, uc.cfg.ResendCooldown)
	uc.emailPublisher.PublishEmail(ctx, &entity.EmailEvent{
		EventType: "FORGOT_PASSWORD_OTP",
		To:        email,
		Subject:   "[DMS Sales] MÃ£ xÃ¡c nháº­n Ä‘áº·t láº¡i máº­t kháº©u",
		Template:  "forgot_password_otp",
		UserID:    user.ID,
		Data: entity.EmailData{
			OTPCode:      otp,
			FullName:     user.FullName,
			ExpiresInMin: int(uc.cfg.OTPTTL.Minutes()),
			IPAddress:    input.IPAddress,
		},
		Timestamp: time.Now(),
	})
	go func() {
		uc.auditPublisher.Publish(context.Background(), &entity.AuditEvent{
			EventType: "FORGOT_PASSWORD_REQUESTED", UserID: user.ID, Username: user.Username,
			IPAddress: input.IPAddress, Timestamp: time.Now(),
		})
	}()
	return nil
}

type ResetPasswordInput struct {
	Email       string
	OTP         string
	NewPassword string
	IPAddress   string
}

func (uc *ForgotPasswordUseCase) ResetPassword(ctx context.Context, input ResetPasswordInput) error {
	email := strings.ToLower(strings.TrimSpace(input.Email))
	otp := strings.TrimSpace(input.OTP)
	if email == "" || otp == "" || input.NewPassword == "" {
		return errors.New("INVALID_REQUEST", "Email, OTP and new password are required", 400)
	}
	if len(input.NewPassword) < 8 {
		return errors.New("INVALID_REQUEST", "Máº­t kháº©u pháº£i cÃ³ Ã­t nháº¥t 8 kÃ½ tá»±", 400)
	}
	savedOTP, err := uc.otpRepo.Get(ctx, email)
	if err != nil {
		return errors.Wrap(err, "failed to get OTP")
	}
	if savedOTP == "" {
		return errors.New("OTP_EXPIRED", "MÃ£ OTP khÃ´ng há»£p lá»‡ hoáº·c Ä‘Ã£ háº¿t háº¡n", 400)
	}
	if savedOTP != otp {
		return errors.New("INVALID_OTP", "MÃ£ OTP khÃ´ng chÃ­nh xÃ¡c", 400)
	}
	user, err := uc.userRepo.FindByEmail(ctx, email)
	if err != nil {
		return errors.ErrUserNotFound
	}
	passwordHash, err := uc.hasher.Hash(input.NewPassword)
	if err != nil {
		return errors.Wrap(err, "failed to hash password")
	}
	if err := uc.userRepo.UpdatePassword(ctx, user.ID, passwordHash); err != nil {
		return errors.Wrap(err, "failed to update password")
	}
	uc.otpRepo.Delete(ctx, email)
	uc.sessionRepo.DeleteByUserID(ctx, user.ID)
	go func() {
		uc.emailPublisher.PublishEmail(context.Background(), &entity.EmailEvent{
			EventType: "PASSWORD_CHANGED", To: email,
			Subject: "[DMS Sales] Máº­t kháº©u Ä‘Ã£ Ä‘Æ°á»£c thay Ä‘á»•i",
			Template: "password_changed", UserID: user.ID,
			Data: entity.EmailData{FullName: user.FullName}, Timestamp: time.Now(),
		})
		uc.auditPublisher.Publish(context.Background(), &entity.AuditEvent{
			EventType: "PASSWORD_RESET_COMPLETED", UserID: user.ID, Username: user.Username,
			IPAddress: input.IPAddress, Timestamp: time.Now(),
		})
	}()
	return nil
}

func generateOTP(length int) (string, error) {
	if length <= 0 {
		length = 6
	}
	max := new(big.Int).Exp(big.NewInt(10), big.NewInt(int64(length)), nil)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%0*d", length, n), nil
}


