import { authedFetch } from './client';

export type EpisodeVisibility = 'public' | 'private' | 'anon';
export type EpisodeMask = 'none' | 'basic' | 'studio';
export type EpisodeQuality = 'raw' | 'clean' | 'studio';

type CreateEpisodeRequest = {
  token: string;
  visibility: EpisodeVisibility;
  topicId?: string;
  mask: EpisodeMask;
  quality: EpisodeQuality;
  durationSec: number;
};

type CreateEpisodeResponse = {
  id: string;
  status: string;
  upload_url: string;
  upload_headers?: Record<string, string>;
};

export async function createEpisode(req: CreateEpisodeRequest): Promise<CreateEpisodeResponse> {
  const body = {
    visibility: req.visibility,
    topic_id: req.topicId ?? null,
    mask: req.mask,
    quality: req.quality,
    duration_sec: req.durationSec
  };

  return authedFetch<CreateEpisodeResponse>(req.token, '/v1/episodes', {
    method: 'POST',
    body: JSON.stringify(body)
  });
}

export async function finalizeEpisode(token: string, episodeId: string): Promise<void> {
  await authedFetch<void>(token, `/v1/episodes/${episodeId}/finalize`, {
    method: 'POST'
  });
}

export async function undoEpisode(token: string, episodeId: string): Promise<void> {
  await authedFetch<void>(token, `/v1/episodes/${episodeId}/undo`, {
    method: 'POST'
  });
}

export async function reactToEpisode(
  token: string,
  episodeId: string,
  type: string,
  remove: boolean = false
): Promise<{ ok: boolean; self: string[] }> {
  return authedFetch<{ ok: boolean; self: string[] }>(token, `/v1/episodes/${episodeId}/react`, {
    method: 'POST',
    body: JSON.stringify({ type, remove })
  });
}

export async function getSelfReactions(
  token: string,
  episodeId: string
): Promise<{ self: string[] }> {
  return authedFetch<{ self: string[] }>(token, `/v1/episodes/${episodeId}/reactions/self`, {
    method: 'GET'
  });
}
