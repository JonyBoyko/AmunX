package auth

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"
)

// MagicLinkToken encapsulates fields embedded into magic link tokens.
type MagicLinkToken struct {
	Email string
	Exp   time.Time
}

// MagicLinkSigner issues and verifies HMAC-based magic link tokens.
type MagicLinkSigner struct {
	secret []byte
	ttl    time.Duration
}

// NewMagicLinkSigner constructs a signer with the given secret and TTL.
func NewMagicLinkSigner(secret string, ttl time.Duration) (*MagicLinkSigner, error) {
	if secret == "" {
		return nil, errors.New("magic link secret is required")
	}
	return &MagicLinkSigner{
		secret: []byte(secret),
		ttl:    ttl,
	}, nil
}

// Sign produces a compact token for the provided email.
func (s *MagicLinkSigner) Sign(email string) (string, error) {
	exp := time.Now().Add(s.ttl).Unix()
	payload := fmt.Sprintf("%s.%d", email, exp)
	mac := hmac.New(sha256.New, s.secret)
	_, _ = mac.Write([]byte(payload))
	sig := mac.Sum(nil)

	token := fmt.Sprintf("%s.%d.%s", email, exp, base64.RawURLEncoding.EncodeToString(sig))
	return base64.RawURLEncoding.EncodeToString([]byte(token)), nil
}

// Verify ensures the token is valid and returns its contents.
func (s *MagicLinkSigner) Verify(token string) (*MagicLinkToken, error) {
	raw, err := base64.RawURLEncoding.DecodeString(token)
	if err != nil {
		return nil, fmt.Errorf("decode token: %w", err)
	}

	parts := strings.Split(string(raw), ".")
	if len(parts) != 3 {
		return nil, errors.New("invalid token format")
	}

	email := parts[0]
	exp, err := strconv.ParseInt(parts[1], 10, 64)
	if err != nil {
		return nil, fmt.Errorf("parse exp: %w", err)
	}

	expectedPayload := fmt.Sprintf("%s.%d", email, exp)
	expectedSig := hmac.New(sha256.New, s.secret)
	_, _ = expectedSig.Write([]byte(expectedPayload))
	expected := expectedSig.Sum(nil)

	provided, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil {
		return nil, fmt.Errorf("decode sig: %w", err)
	}

	if !hmac.Equal(expected, provided) {
		return nil, errors.New("invalid token signature")
	}

	if time.Now().Unix() > exp {
		return nil, errors.New("token expired")
	}

	return &MagicLinkToken{
		Email: email,
		Exp:   time.Unix(exp, 0),
	}, nil
}
