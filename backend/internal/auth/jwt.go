package auth

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Claims represents JWT claims for the API.
type Claims struct {
	UserID string `json:"uid"`
	Plan   string `json:"plan,omitempty"`

	jwt.RegisteredClaims
}

// JWTManager handles issuing and validating access/refresh tokens.
type JWTManager struct {
	accessSecret  []byte
	refreshSecret []byte
	accessTTL     time.Duration
	refreshTTL    time.Duration
}

// NewJWTManager constructs a new JWTManager.
func NewJWTManager(accessSecret, refreshSecret string, accessTTL, refreshTTL time.Duration) *JWTManager {
	return &JWTManager{
		accessSecret:  []byte(accessSecret),
		refreshSecret: []byte(refreshSecret),
		accessTTL:     accessTTL,
		refreshTTL:    refreshTTL,
	}
}

// IssueAccess creates a signed access token.
func (m *JWTManager) IssueAccess(userID, plan string) (string, error) {
	now := time.Now()
	claims := Claims{
		UserID: userID,
		Plan:   plan,
		RegisteredClaims: jwt.RegisteredClaims{
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(m.accessTTL)),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(m.accessSecret)
}

// IssueRefresh creates a signed refresh token.
func (m *JWTManager) IssueRefresh(userID string) (string, error) {
	now := time.Now()
	claims := Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(m.refreshTTL)),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(m.refreshSecret)
}

// VerifyAccess validates an access token and returns claims.
func (m *JWTManager) VerifyAccess(token string) (*Claims, error) {
	return m.verify(token, m.accessSecret)
}

// VerifyRefresh validates a refresh token and returns claims.
func (m *JWTManager) VerifyRefresh(token string) (*Claims, error) {
	return m.verify(token, m.refreshSecret)
}

func (m *JWTManager) verify(token string, secret []byte) (*Claims, error) {
	parsed, err := jwt.ParseWithClaims(token, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		return secret, nil
	}, jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Name}))
	if err != nil {
		return nil, err
	}

	claims, ok := parsed.Claims.(*Claims)
	if !ok || !parsed.Valid {
		return nil, jwt.ErrTokenInvalidClaims
	}

	return claims, nil
}

