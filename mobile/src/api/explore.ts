import { apiClient } from './client';

export interface ExploreCard {
  id: string;
  kind: 'audio_item' | 'clip';
  parent_audio_id?: string;
  owner: {
    id: string;
    display_name: string;
    avatar_url?: string;
  };
  duration_sec: number;
  preview_sentence?: string;
  title?: string;
  quote?: string;
  tags?: string[];
  waveform_peaks?: number[];
  audio_url: string;
  created_at: string;
  stats?: {
    likes: number;
    plays: number;
  };
}

export interface ExploreFeedResponse {
  cards: ExploreCard[];
  next_cursor?: string;
  has_more: boolean;
}

export interface ExploreFeedParams {
  cursor?: string;
  topics?: string; // Comma-separated
  city?: string;
  len?: string; // e.g., "30..120"
  limit?: number;
}

/**
 * Get the Explore feed with ranked cards
 */
async function getFeed(params: ExploreFeedParams = {}): Promise<ExploreFeedResponse> {
  const queryParams = new URLSearchParams();

  if (params.cursor) queryParams.append('cursor', params.cursor);
  if (params.topics) queryParams.append('topics', params.topics);
  if (params.city) queryParams.append('city', params.city);
  if (params.len) queryParams.append('len', params.len);
  if (params.limit) queryParams.append('limit', params.limit.toString());

  const url = `/explore${queryParams.toString() ? `?${queryParams.toString()}` : ''}`;

  return apiClient<ExploreFeedResponse>({
    method: 'GET',
    endpoint: url,
  });
}

export const exploreAPI = {
  getFeed,
};

