import { apiClient } from './client';

export interface CreateAudioItemParams {
  s3_key: string;
  duration_sec: number;
  kind: 'micro' | 'podcast_episode';
  title?: string;
  description?: string;
  tags?: string[];
  visibility?: 'private' | 'circles' | 'public';
  share_to_circle_ids?: string[];
}

export interface AudioItem {
  id: string;
  owner_id: string;
  visibility: string;
  title: string;
  description: string;
  kind: string;
  duration_sec: number;
  audio_url: string;
  tags: string[];
  created_at: string;
}

async function createAudioItem(params: CreateAudioItemParams): Promise<AudioItem> {
  return apiClient<AudioItem>({
    method: 'POST',
    endpoint: '/audio',
    body: params,
  });
}

async function getAudioItem(id: string): Promise<AudioItem> {
  return apiClient<AudioItem>({
    method: 'GET',
    endpoint: `/audio/${id}`,
  });
}

async function likeAudioItem(id: string): Promise<void> {
  return apiClient<void>({
    method: 'POST',
    endpoint: `/audio/${id}/like`,
  });
}

async function unlikeAudioItem(id: string): Promise<void> {
  return apiClient<void>({
    method: 'DELETE',
    endpoint: `/audio/${id}/like`,
  });
}

async function saveAudioItem(id: string): Promise<void> {
  return apiClient<void>({
    method: 'POST',
    endpoint: `/audio/${id}/save`,
  });
}

async function unsaveAudioItem(id: string): Promise<void> {
  return apiClient<void>({
    method: 'DELETE',
    endpoint: `/audio/${id}/save`,
  });
}

export const audioAPI = {
  createAudioItem,
  getAudioItem,
  likeAudioItem,
  unlikeAudioItem,
  saveAudioItem,
  unsaveAudioItem,
};

