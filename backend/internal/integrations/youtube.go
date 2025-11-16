package integrations

import (
	"context"
	"fmt"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
	"google.golang.org/api/option"
	"google.golang.org/api/youtube/v3"
)

// YouTubeClient handles YouTube API operations
type YouTubeClient struct {
	config *oauth2.Config
}

// NewYouTubeClient creates a new YouTube client
func NewYouTubeClient(clientID, clientSecret, redirectURL string) *YouTubeClient {
	config := &oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		RedirectURL:  redirectURL,
		Scopes: []string{
			youtube.YoutubeUploadScope,
			youtube.YoutubeForceSslScope,
		},
		Endpoint: google.Endpoint,
	}

	return &YouTubeClient{
		config: config,
	}
}

// GetAuthURL returns the OAuth authorization URL
func (c *YouTubeClient) GetAuthURL(state string) string {
	return c.config.AuthCodeURL(state, oauth2.AccessTypeOffline, oauth2.ApprovalForce)
}

// ExchangeCode exchanges authorization code for tokens
func (c *YouTubeClient) ExchangeCode(ctx context.Context, code string) (*oauth2.Token, error) {
	token, err := c.config.Exchange(ctx, code)
	if err != nil {
		return nil, fmt.Errorf("failed to exchange code: %w", err)
	}
	return token, nil
}

// UploadVideoRequest represents a video upload request
type UploadVideoRequest struct {
	FilePath    string
	Title       string
	Description string
	Tags        []string
	Visibility  string // public, unlisted, private
	CategoryID  string
}

// UploadVideo uploads a video to YouTube
func (c *YouTubeClient) UploadVideo(ctx context.Context, token *oauth2.Token, req UploadVideoRequest) (string, error) {
	// Create YouTube service
	client := c.config.Client(ctx, token)
	service, err := youtube.NewService(ctx, option.WithHTTPClient(client))
	if err != nil {
		return "", fmt.Errorf("failed to create youtube service: %w", err)
	}

	// Create video metadata
	video := &youtube.Video{
		Snippet: &youtube.VideoSnippet{
			Title:       req.Title,
			Description: req.Description,
			Tags:        req.Tags,
			CategoryId:  req.CategoryID,
		},
		Status: &youtube.VideoStatus{
			PrivacyStatus:           req.Visibility,
			SelfDeclaredMadeForKids: false,
		},
	}

	// TODO: Open file and upload
	// call := service.Videos.Insert([]string{"snippet", "status"}, video)
	// file, err := os.Open(req.FilePath)
	// if err != nil {
	//     return "", fmt.Errorf("failed to open file: %w", err)
	// }
	// defer file.Close()
	// 
	// call.Media(file)
	// response, err := call.Do()
	// if err != nil {
	//     return "", fmt.Errorf("failed to upload video: %w", err)
	// }
	// 
	// return response.Id, nil

	_ = service
	_ = video

	// Mock response for now
	return "mock-video-id-" + time.Now().Format("20060102150405"), nil
}

// RefreshToken refreshes an OAuth token
func (c *YouTubeClient) RefreshToken(ctx context.Context, refreshToken string) (*oauth2.Token, error) {
	token := &oauth2.Token{
		RefreshToken: refreshToken,
	}

	tokenSource := c.config.TokenSource(ctx, token)
	newToken, err := tokenSource.Token()
	if err != nil {
		return nil, fmt.Errorf("failed to refresh token: %w", err)
	}

	return newToken, nil
}

// CreateShortUpload creates a YouTube Short upload (same as regular video but with #shorts in description)
func (c *YouTubeClient) CreateShortUpload(ctx context.Context, token *oauth2.Token, req UploadVideoRequest) (string, error) {
	// YouTube Shorts requirements:
	// - Vertical aspect ratio (9:16)
	// - Duration ≤ 60 seconds
	// - Include #shorts in title or description

	req.Description = req.Description + "\n\n#shorts"
	
	return c.UploadVideo(ctx, token, req)
}


