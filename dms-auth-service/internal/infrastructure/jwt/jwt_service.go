package jwt

import (
	"github.com/nextdms/authservice/configs"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	UserID      string   `json:"user_id"`
	Username    string   `json:"username"`
	Role        string   `json:"role"`
	Permissions []string `json:"permissions"`
	DeviceID    string   `json:"device_id"`
	jwt.RegisteredClaims
}

type JWTService struct {
	secret      []byte
	expiry      time.Duration
	issuer      string
}

func NewJWTService(cfg configs.JWTConfig) *JWTService {
	expiry, _ := time.ParseDuration(cfg.AccessTokenExpiry)
	if expiry == 0 {
		expiry = 15 * time.Minute
	}
	return &JWTService{
		secret: []byte(cfg.AccessTokenSecret),
		expiry: expiry,
		issuer: cfg.Issuer,
	}
}

func (s *JWTService) Generate(userID, username, role string, permissions []string, deviceID string) (string, int64, error) {
	now := time.Now()
	expiresAt := now.Add(s.expiry)

	claims := Claims{
		UserID:      userID,
		Username:    username,
		Role:        role,
		Permissions: permissions,
		DeviceID:    deviceID,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    s.issuer,
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
			NotBefore: jwt.NewNumericDate(now),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(s.secret)
	if err != nil {
		return "", 0, err
	}

	return tokenString, int64(s.expiry.Seconds()), nil
}

func (s *JWTService) Verify(tokenString string) (*Claims, error) {
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return s.secret, nil
	})

	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, errors.New("invalid token")
	}

	return claims, nil
}
