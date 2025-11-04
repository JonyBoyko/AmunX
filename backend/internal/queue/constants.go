package queue

const (
	// TopicProcessAudio is the stream where audio processing jobs are published.
	TopicProcessAudio = "jobs:process_audio"

	// TopicFinalizeLive handles post-processing for completed live sessions.
	TopicFinalizeLive = "jobs:finalize_live"
)
