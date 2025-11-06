package http

import (
	"encoding/json"
	"errors"
	"net/http"
)

// WriteJSON writes the given body as JSON with the provided status code.
func WriteJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

// WriteError wraps WriteJSON to emit a standard error payload.
func WriteError(w http.ResponseWriter, status int, code, message string) {
	WriteJSON(w, status, map[string]string{
		"error":             code,
		"error_description": message,
	})
}

// decodeJSON decodes a request body into the destination while disallowing unknown fields.
func decodeJSON(r *http.Request, dst any) error {
	if r.Body == nil {
		return errors.New("missing body")
	}
	defer r.Body.Close()

	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	return decoder.Decode(dst)
}

