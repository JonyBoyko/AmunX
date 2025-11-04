import { authedFetch, apiFetch } from './client';

export type Comment = {
  id: string;
  episode_id: string;
  author_id: string;
  text: string;
  created_at: string;
};

export async function listComments(episodeId: string, after?: string): Promise<{ items: Comment[] }> {
  const qs = after ? `?after=${encodeURIComponent(after)}` : '';
  return apiFetch<{ items: Comment[] }>(`/v1/episodes/${episodeId}/comments${qs}`);
}

export async function postComment(token: string, episodeId: string, text: string): Promise<{ comment: Comment; flagged: boolean }> {
  return authedFetch<{ comment: Comment; flagged: boolean }>(token, `/v1/episodes/${episodeId}/comments`, {
    method: 'POST',
    body: JSON.stringify({ text })
  });
}

