package logger

import (
	"os"
	"time"

	"github.com/rs/zerolog"
)

// New builds a zerolog.Logger configured for console output in development or JSON otherwise.
func New(env string) zerolog.Logger {
	level := zerolog.InfoLevel
	if env == "development" || env == "dev" {
		level = zerolog.DebugLevel
	}

	output := zerolog.ConsoleWriter{
		Out:        os.Stdout,
		TimeFormat: time.RFC3339,
		NoColor:    false,
	}
	if env != "development" && env != "dev" {
		output = zerolog.ConsoleWriter{
			Out:        os.Stdout,
			TimeFormat: time.RFC3339,
			NoColor:    true,
		}
	}

	logger := zerolog.New(output).With().Timestamp().Logger()
	return logger.Level(level)
}

