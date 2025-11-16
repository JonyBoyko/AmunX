package worker

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/google/uuid"
)

// AudiogramJob represents an audiogram generation job
type AudiogramJob struct {
	JobID        string    `json:"job_id"`
	AudioID      string    `json:"audio_id"`
	ClipID       *string   `json:"clip_id"`
	StartSec     *int      `json:"start_sec"`
	EndSec       *int      `json:"end_sec"`
	StylePreset  string    `json:"style_preset"` // clean, waveform, subtitle
	SubtitleLang string    `json:"subtitle_lang"`
	CoverText    string    `json:"cover_text"`
	Status       string    `json:"status"` // queued, running, succeeded, failed
	S3Key        string    `json:"s3_key"`
	Error        string    `json:"error"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// AudiogramWorker handles audiogram generation
type AudiogramWorker struct {
	storageClient StorageClient
	tempDir       string
	ffmpegPath    string
}

// StorageClient interface for S3 operations
type StorageClient interface {
	Download(ctx context.Context, s3Key string, localPath string) error
	Upload(ctx context.Context, localPath string, s3Key string) error
	GetSignedURL(ctx context.Context, s3Key string, expiry time.Duration) (string, error)
}

// NewAudiogramWorker creates a new audiogram worker
func NewAudiogramWorker(storageClient StorageClient, tempDir string) *AudiogramWorker {
	return &AudiogramWorker{
		storageClient: storageClient,
		tempDir:       tempDir,
		ffmpegPath:    "ffmpeg", // Assumes ffmpeg is in PATH
	}
}

// ProcessJob processes an audiogram generation job
func (w *AudiogramWorker) ProcessJob(ctx context.Context, job *AudiogramJob) error {
	job.Status = "running"
	job.UpdatedAt = time.Now()

	// Create temp directory for this job
	jobDir := filepath.Join(w.tempDir, job.JobID)
	if err := os.MkdirAll(jobDir, 0755); err != nil {
		return fmt.Errorf("failed to create job directory: %w", err)
	}
	defer os.RemoveAll(jobDir) // Cleanup

	// Download audio file from S3
	audioPath := filepath.Join(jobDir, "audio.m4a")
	// TODO: Get actual S3 key from audio_items table
	audioS3Key := fmt.Sprintf("audio/%s.m4a", job.AudioID)
	if err := w.storageClient.Download(ctx, audioS3Key, audioPath); err != nil {
		job.Status = "failed"
		job.Error = fmt.Sprintf("failed to download audio: %v", err)
		return err
	}

	// Download transcript for subtitles
	// TODO: Fetch from transcripts table
	transcriptPath := filepath.Join(jobDir, "transcript.json")
	
	// Generate audiogram based on style
	outputPath := filepath.Join(jobDir, "audiogram.mp4")
	
	switch job.StylePreset {
	case "subtitle":
		if err := w.generateWithSubtitles(ctx, job, audioPath, transcriptPath, outputPath); err != nil {
			job.Status = "failed"
			job.Error = fmt.Sprintf("failed to generate: %v", err)
			return err
		}
	case "waveform":
		if err := w.generateWithWaveform(ctx, job, audioPath, outputPath); err != nil {
			job.Status = "failed"
			job.Error = fmt.Sprintf("failed to generate: %v", err)
			return err
		}
	case "clean":
		if err := w.generateClean(ctx, job, audioPath, outputPath); err != nil {
			job.Status = "failed"
			job.Error = fmt.Sprintf("failed to generate: %v", err)
			return err
		}
	default:
		job.Status = "failed"
		job.Error = "invalid style preset"
		return fmt.Errorf("invalid style preset: %s", job.StylePreset)
	}

	// Upload to S3
	outputS3Key := fmt.Sprintf("audiograms/%s.mp4", job.JobID)
	if err := w.storageClient.Upload(ctx, outputPath, outputS3Key); err != nil {
		job.Status = "failed"
		job.Error = fmt.Sprintf("failed to upload: %v", err)
		return err
	}

	job.Status = "succeeded"
	job.S3Key = outputS3Key
	job.UpdatedAt = time.Now()
	return nil
}

// generateWithSubtitles generates audiogram with burnt-in subtitles
func (w *AudiogramWorker) generateWithSubtitles(ctx context.Context, job *AudiogramJob, audioPath, transcriptPath, outputPath string) error {
	// Generate SRT subtitle file from transcript
	_ = filepath.Join(filepath.Dir(outputPath), "subtitles.srt")  // srtPath - TODO: use when SRT generation implemented
	// TODO: Parse transcript JSON and generate SRT

	// FFmpeg command to create 1080x1920 video with waveform and subtitles
	cmd := exec.CommandContext(ctx,
		w.ffmpegPath,
		"-i", audioPath,
		"-f", "lavfi",
		"-i", "color=c=black:s=1080x1920:d=30", // Black background
		"-filter_complex",
		"[0:a]showwaves=s=1080x400:mode=line:colors=white[waves];"+
			"[1:v][waves]overlay=(W-w)/2:800[video];"+
			"[video]drawtext=text='"+job.CoverText+"':fontsize=48:fontcolor=white:x=(w-text_w)/2:y=300[out]",
		"-map", "[out]",
		"-map", "0:a",
		"-c:v", "libx264",
		"-preset", "fast",
		"-crf", "23",
		"-c:a", "aac",
		"-b:a", "128k",
		"-movflags", "+faststart",
		"-y",
		outputPath,
	)

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("ffmpeg failed: %w, output: %s", err, string(output))
	}

	return nil
}

// generateWithWaveform generates audiogram with animated waveform
func (w *AudiogramWorker) generateWithWaveform(ctx context.Context, job *AudiogramJob, audioPath, outputPath string) error {
	cmd := exec.CommandContext(ctx,
		w.ffmpegPath,
		"-i", audioPath,
		"-filter_complex",
		"[0:a]showwaves=s=1080x1920:mode=cline:colors=0x00FF00:scale=sqrt[v]",
		"-map", "[v]",
		"-map", "0:a",
		"-c:v", "libx264",
		"-preset", "fast",
		"-crf", "23",
		"-c:a", "aac",
		"-b:a", "128k",
		"-movflags", "+faststart",
		"-y",
		outputPath,
	)

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("ffmpeg failed: %w, output: %s", err, string(output))
	}

	return nil
}

// generateClean generates minimal audiogram (static image + audio)
func (w *AudiogramWorker) generateClean(ctx context.Context, job *AudiogramJob, audioPath, outputPath string) error {
	cmd := exec.CommandContext(ctx,
		w.ffmpegPath,
		"-f", "lavfi",
		"-i", "color=c=black:s=1080x1920:d=30",
		"-i", audioPath,
		"-filter_complex",
		"[0:v]drawtext=text='"+job.CoverText+"':fontsize=64:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2[v]",
		"-map", "[v]",
		"-map", "1:a",
		"-c:v", "libx264",
		"-preset", "fast",
		"-crf", "23",
		"-c:a", "aac",
		"-b:a", "128k",
		"-shortest",
		"-movflags", "+faststart",
		"-y",
		outputPath,
	)

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("ffmpeg failed: %w, output: %s", err, string(output))
	}

	return nil
}

// QueueAudiogramJob queues an audiogram job to Redis
func QueueAudiogramJob(ctx context.Context, redisClient interface{}, job *AudiogramJob) error {
	job.JobID = uuid.New().String()
	job.Status = "queued"
	job.CreatedAt = time.Now()
	job.UpdatedAt = time.Now()

	jobJSON, err := json.Marshal(job)
	if err != nil {
		return fmt.Errorf("failed to marshal job: %w", err)
	}

	// TODO: Push to Redis queue
	// redisClient.LPush(ctx, "audiogram_jobs", jobJSON)
	_ = jobJSON

	return nil
}

// GetAudiogramJobStatus retrieves job status from Redis
func GetAudiogramJobStatus(ctx context.Context, redisClient interface{}, jobID string) (*AudiogramJob, error) {
	// TODO: Get from Redis hash or database
	// jobJSON, err := redisClient.Get(ctx, "audiogram_job:"+jobID).Bytes()
	
	return &AudiogramJob{
		JobID:  jobID,
		Status: "queued",
	}, nil
}


