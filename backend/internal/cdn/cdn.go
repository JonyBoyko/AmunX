package cdn

import (
	"fmt"
	"net/http"
)

// AddCacheHeaders applies cache control headers depending on visibility.
func AddCacheHeaders(w http.ResponseWriter, isPublic bool, ttlSeconds int) {
	if isPublic {
		w.Header().Set("Cache-Control", "public, max-age="+itoa(ttlSeconds))
		return
	}
	w.Header().Set("Cache-Control", "no-store")
}

func itoa(v int) string {
	return fmt.Sprintf("%d", v)
}
