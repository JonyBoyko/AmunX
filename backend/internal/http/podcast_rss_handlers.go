package http

import (
	"encoding/xml"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	"github.com/amunx/backend/internal/app"
)

// RSS 2.0 specification structs
type RSS struct {
	XMLName xml.Name `xml:"rss"`
	Version string   `xml:"version,attr"`
	XMLNS   string   `xml:"xmlns:itunes,attr"`
	Channel Channel  `xml:"channel"`
}

type Channel struct {
	Title       string `xml:"title"`
	Description string `xml:"description"`
	Link        string `xml:"link"`
	Language    string `xml:"language"`
	Copyright   string `xml:"copyright"`
	Image       Image  `xml:"image"`
	ITunesImage string `xml:"itunes:image"`
	Items       []Item `xml:"item"`
}

type Image struct {
	URL   string `xml:"url"`
	Title string `xml:"title"`
	Link  string `xml:"link"`
}

type Item struct {
	Title       string    `xml:"title"`
	Description string    `xml:"description"`
	PubDate     string    `xml:"pubDate"`
	Enclosure   Enclosure `xml:"enclosure"`
	GUID        string    `xml:"guid"`
	Duration    string    `xml:"itunes:duration"`
}

type Enclosure struct {
	URL    string `xml:"url,attr"`
	Type   string `xml:"type,attr"`
	Length int64  `xml:"length,attr"`
}

// GetPodcastRSS serves the RSS feed for a podcast show (GET /podcasts/rss/:slug.xml)
func GetPodcastRSS(w http.ResponseWriter, r *http.Request, deps *app.App) {
	slug := chi.URLParam(r, "slug")
	if slug == "" {
		http.Error(w, "slug required", http.StatusBadRequest)
		return
	}

	// TODO: Fetch podcast show by slug using sqlc
	// TODO: Fetch episodes using sqlc
	// TODO: For each episode, get audio_item details

	// Mock response
	rss := RSS{
		Version: "2.0",
		XMLNS:   "http://www.itunes.com/dtds/podcast-1.0.dtd",
		Channel: Channel{
			Title:       "My Awesome Podcast",
			Description: "Weekly discussions about tech",
			Link:        "https://amunx.com/podcasts/" + slug,
			Language:    "en-us",
			Copyright:   "© 2025 AmunX",
			Image: Image{
				URL:   "https://cdn.amunx.com/podcasts/" + slug + "/cover.jpg",
				Title: "My Awesome Podcast",
				Link:  "https://amunx.com/podcasts/" + slug,
			},
			ITunesImage: "https://cdn.amunx.com/podcasts/" + slug + "/cover.jpg",
			Items: []Item{
				{
					Title:       "Episode 1: Getting Started",
					Description: "In this episode, we discuss how to get started with podcasting.",
					PubDate:     time.Now().Add(-7 * 24 * time.Hour).Format(time.RFC1123Z),
					Enclosure: Enclosure{
						URL:    "https://cdn.amunx.com/audio/episode1.mp3",
						Type:   "audio/mpeg",
						Length: 15000000,
					},
					GUID:     "https://amunx.com/audio/episode1",
					Duration: "25:30",
				},
			},
		},
	}

	// Set headers
	w.Header().Set("Content-Type", "application/rss+xml; charset=utf-8")

	// Encode XML
	w.Write([]byte(xml.Header))
	encoder := xml.NewEncoder(w)
	encoder.Indent("", "  ")
	if err := encoder.Encode(rss); err != nil {
		http.Error(w, "failed to encode RSS", http.StatusInternalServerError)
		return
	}
}

// CreatePodcastShow creates a new podcast show (POST /podcasts/shows)
func CreatePodcastShow(w http.ResponseWriter, r *http.Request, deps *app.App) {
	// TODO: Implement
	WriteJSON(w, http.StatusNotImplemented, map[string]string{"status": "not implemented"})
}

// AddPodcastEpisode adds an audio item as podcast episode (POST /podcasts/shows/:id/episodes)
func AddPodcastEpisode(w http.ResponseWriter, r *http.Request, deps *app.App) {
	// TODO: Implement
	WriteJSON(w, http.StatusNotImplemented, map[string]string{"status": "not implemented"})
}

// registerPodcastRoutes registers routes for podcast RSS
func registerPodcastRoutes(r chi.Router, deps *app.App) {
	r.Get("/podcasts/rss/{slug}.xml", func(w http.ResponseWriter, req *http.Request) {
		GetPodcastRSS(w, req, deps)
	})

	r.Post("/podcasts/shows", func(w http.ResponseWriter, req *http.Request) {
		CreatePodcastShow(w, req, deps)
	})

	r.Post("/podcasts/shows/{id}/episodes", func(w http.ResponseWriter, req *http.Request) {
		AddPodcastEpisode(w, req, deps)
	})
}


