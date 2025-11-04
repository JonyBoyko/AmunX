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

/**
 * Upload episode (wrapper for create + upload + finalize flow)
 */
export async function uploadEpisode(
  token: string,
  formData: FormData
): Promise<{ id: string; status: string }> {
  // Extract metadata from FormData
  const isPublic = formData.get('is_public') === 'true';
  const mask = (formData.get('mask') as EpisodeMask) || 'none';
  const quality = (formData.get('quality') as EpisodeQuality) || 'clean';
  const audioFile = formData.get('audio') as any;

  // Step 1: Create episode and get upload URL
  const createResponse = await createEpisode({
    token,
    visibility: isPublic ? 'public' : 'private',
    mask,
    quality,
    durationSec: 60, // Default to 60s, will be updated after processing
  });

  // Step 2: Upload audio file to S3
  const uploadHeaders: Record<string, string> = createResponse.upload_headers || {
    'Content-Type': 'audio/m4a',
  };

  const uploadResponse = await fetch(createResponse.upload_url, {
    method: 'PUT',
    headers: uploadHeaders,
    body: audioFile.uri ? await fetch(audioFile.uri).then((r) => r.blob()) : audioFile,
  });

  if (!uploadResponse.ok) {
    throw new Error(`Upload failed: ${uploadResponse.statusText}`);
  }

  // Step 3: Finalize episode
  await finalizeEpisode(token, createResponse.id);

  return { id: createResponse.id, status: 'processing' };
}

/**
 * Delete episode (alias for undoEpisode)
 */
export async function deleteEpisode(token: string, episodeId: string): Promise<void> {
  return undoEpisode(token, episodeId);
}
