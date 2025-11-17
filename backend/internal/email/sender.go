package email

import (
	"context"
	"fmt"
	"net/smtp"
	"strings"

	"github.com/rs/zerolog"
)

// Sender describes an email sender implementation.
type Sender interface {
	SendMagicLink(ctx context.Context, to, link string) error
}

// Options contains SMTP configuration.
type Options struct {
	Host     string
	Port     int
	Username string
	Password string
	From     string
}

// NewSender constructs a Sender based on provided options.
func NewSender(opts Options, logger zerolog.Logger) Sender {
	if opts.Host == "" || opts.From == "" {
		logger.Warn().Msg("email sender disabled: SMTP_HOST or EMAIL_FROM not configured")
		return &noopSender{logger: logger}
	}
	return &smtpSender{
		opts:   opts,
		logger: logger,
	}
}

type noopSender struct {
	logger zerolog.Logger
}

func (n *noopSender) SendMagicLink(ctx context.Context, to, link string) error {
	n.logger.Info().
		Str("email", to).
		Str("link", link).
		Msg("magic link (noop sender)")
	return nil
}

type smtpSender struct {
	opts   Options
	logger zerolog.Logger
}

func (s *smtpSender) SendMagicLink(ctx context.Context, to, link string) error {
	addr := fmt.Sprintf("%s:%d", s.opts.Host, s.opts.Port)
	body := buildMessage(s.opts.From, to, link)
	var auth smtp.Auth
	if s.opts.Username != "" {
		auth = smtp.PlainAuth("", s.opts.Username, s.opts.Password, s.opts.Host)
	}
	if err := smtp.SendMail(addr, auth, s.opts.From, []string{to}, []byte(body)); err != nil {
		s.logger.Error().Err(err).Str("email", to).Msg("failed to send magic link email")
		return err
	}
	return nil
}

func buildMessage(from, to, link string) string {
	var b strings.Builder
	b.WriteString("From: " + from + "\r\n")
	b.WriteString("To: " + to + "\r\n")
	b.WriteString("Subject: Sign in to Moweton\r\n")
	b.WriteString("MIME-Version: 1.0\r\n")
	b.WriteString("Content-Type: text/plain; charset=\"UTF-8\"\r\n")
	b.WriteString("\r\n")
	b.WriteString("Привіт!\r\n\r\n")
	b.WriteString("Натисни на посилання, щоб увійти у Moweton:\r\n")
	b.WriteString(link + "\r\n\r\n")
	b.WriteString("Із любов’ю,\r\nКоманда Moweton\r\n")
	return b.String()
}
