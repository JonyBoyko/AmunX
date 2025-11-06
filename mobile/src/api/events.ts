import { apiClient } from './client';

export type FeedEventType =
  | 'impression'
  | 'preview_finished'
  | 'play'
  | 'complete'
  | 'save'
  | 'share'
  | 'quote'
  | 'follow_author';

export interface RecordFeedEventParams {
  audio_id: string;
  event: FeedEventType;
  meta?: Record<string, any>;
}

/**
 * Record a user engagement event for the Explore feed ranking
 */
export async function recordFeedEvent(params: RecordFeedEventParams): Promise<void> {
  await apiClient<void>({
    method: 'POST',
    endpoint: '/events',
    body: params,
  });
}

