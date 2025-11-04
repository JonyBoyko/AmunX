import { useQuery } from '@tanstack/react-query';

import { authedFetch, apiFetch } from './client';

export type FeedEpisode = {
  id: string;
  author_id: string;
  topic_id?: string;
  title?: string;
  visibility: string;
  status: string;
  duration_sec?: number;
  audio_url?: string;
  mask: string;
  quality: string;
  is_live: boolean;
  published_at?: string;
  created_at: string;
  summary?: string;
  keywords?: string[];
  mood?: Record<string, unknown>;
};

export type FeedResponse = {
  items: FeedEpisode[];
};

export function useFeedQuery(token?: string | null) {
  return useQuery({
    queryKey: ['feed', token],
    queryFn: async () => {
      if (token) {
        return authedFetch<FeedResponse>(token, '/v1/episodes');
      }
      return apiFetch<FeedResponse>('/v1/episodes');
    }
  });
}

export async function getEpisodeById(id: string): Promise<FeedEpisode> {
  const res = await apiFetch<FeedEpisode>(`/v1/episodes/${id}`);
  return res;
}
