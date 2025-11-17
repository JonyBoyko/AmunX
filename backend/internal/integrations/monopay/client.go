package monopay

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/rs/zerolog"
)

type Config struct {
	BaseURL  string
	APIToken string
	Merchant string
	Logger   zerolog.Logger
}

type Client struct {
	baseURL  string
	apiKey   string
	merchant string
	http     *http.Client
	logger   zerolog.Logger
}

func NewClient(cfg Config) *Client {
	base := strings.TrimSuffix(cfg.BaseURL, "/")
	if base == "" {
		base = "https://api.monobank.ua/api/merchant"
	}
	return &Client{
		baseURL:  base,
		apiKey:   cfg.APIToken,
		merchant: cfg.Merchant,
		http:     &http.Client{Timeout: 10 * time.Second},
		logger:   cfg.Logger,
	}
}

type InvoiceRequest struct {
	AmountCents  int
	Currency     string
	Reference    string
	Destination  string
	RedirectURL  string
	WebhookURL   string
	CustomerData map[string]string
	Validity     time.Duration
}

type InvoiceResponse struct {
	InvoiceID string `json:"invoiceId"`
	PageURL   string `json:"pageUrl"`
}

func (c *Client) CreateInvoice(ctx context.Context, req InvoiceRequest) (*InvoiceResponse, error) {
	payload := map[string]any{
		"amount": req.AmountCents,
		"ccy":    currencyCode(req.Currency),
		"merchantPaymInfo": map[string]any{
			"reference":   req.Reference,
			"destination": req.Destination,
		},
		"redirectUrl": req.RedirectURL,
		"webHookUrl":  req.WebhookURL,
		"validity":    int(req.Validity.Seconds()),
		"paymentType": "debit",
		"merchantId":  c.merchant,
	}
	if len(req.CustomerData) > 0 {
		if data, err := json.Marshal(req.CustomerData); err == nil {
			payload["customerData"] = string(data)
		}
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("%s/invoice/create", c.baseURL)
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("X-Token", c.apiKey)

	resp, err := c.http.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("monopay create invoice failed with %d", resp.StatusCode)
	}

	var invoice InvoiceResponse
	if err := json.NewDecoder(resp.Body).Decode(&invoice); err != nil {
		return nil, err
	}
	return &invoice, nil
}

func currencyCode(currency string) int {
	switch strings.ToUpper(currency) {
	case "UAH":
		return 980
	case "USD":
		return 840
	case "EUR":
		return 978
	default:
		return 980
	}
}
