package billing

import (
	"database/sql"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
)

type Provider string

const (
	ProviderStripe     Provider = "stripe"
	ProviderRevenueCat Provider = "revenuecat"
	ProviderMonoPay    Provider = "monopay"
)

type SubscriptionStatus string

const (
	StatusTrialing SubscriptionStatus = "trialing"
	StatusActive   SubscriptionStatus = "active"
	StatusPastDue  SubscriptionStatus = "past_due"
	StatusCanceled SubscriptionStatus = "canceled"
	StatusExpired  SubscriptionStatus = "expired"
)

var activeStatuses = map[SubscriptionStatus]bool{
	StatusActive:   true,
	StatusTrialing: true,
}

type Product struct {
	ID          uuid.UUID       `json:"id"`
	Code        string          `json:"code"`
	Name        string          `json:"name"`
	Description string          `json:"description"`
	Provider    Provider        `json:"provider"`
	ExternalID  string          `json:"external_id"`
	Currency    string          `json:"currency"`
	AmountCents int             `json:"amount_cents"`
	Interval    string          `json:"interval"`
	Metadata    json.RawMessage `json:"metadata"`
}

type SubscriptionSnapshot struct {
	ProductCode      string             `json:"product_code"`
	Status           SubscriptionStatus `json:"status"`
	Provider         Provider           `json:"provider"`
	CurrentPeriodEnd *time.Time         `json:"current_period_end,omitempty"`
}

var (
	ErrProductNotFound      = errors.New("billing product not found")
	ErrInvalidProvider      = errors.New("invalid billing provider")
	ErrSubscriptionNotFound = errors.New("subscription not found")
)

type SubscriptionUpdate struct {
	UserID                 uuid.UUID
	Provider               Provider
	ProductCode            string
	ProductName            string
	ProductDescription     string
	ExternalProductID      string
	ExternalSubscriptionID string
	ExternalCustomerID     string
	Currency               string
	AmountCents            int
	Interval               string
	Status                 SubscriptionStatus
	CurrentPeriodEnd       *time.Time
	CancelAt               *time.Time
	CanceledAt             *time.Time
	EntitlementCode        string
	EntitlementExpires     *time.Time
	Metadata               map[string]any
	RawEvent               json.RawMessage
}

type ProductStore interface {
	ListProducts() ([]Product, error)
}

func (p Provider) Valid() bool {
	switch p {
	case ProviderStripe, ProviderRevenueCat, ProviderMonoPay:
		return true
	default:
		return false
	}
}

func ScanNullableJSON(src sql.NullString) json.RawMessage {
	if !src.Valid || src.String == "" {
		return json.RawMessage(`{}`)
	}
	return json.RawMessage(src.String)
}
