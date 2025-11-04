import { apiFetch, authedFetch } from './client';

export type LiveSession = {
  id: string;
  room: string;
  host_id: string;
  topic_id?: string | null;
  title?: string | null;
  started_at: string;
  ended_at?: string | null;
};

export type LiveSessionCreateResponse = {
  session: LiveSession;
  token: string;
  url: string;
};

export async function createLiveSession(
  token: string,
  payload: { topic_id?: string | null; title?: string }
): Promise<LiveSessionCreateResponse> {
  return authedFetch(token, '/v1/live/sessions', {
    method: 'POST',
    body: JSON.stringify(payload)
  });
}

export async function endLiveSession(
  token: string,
  sessionId: string,
  payload: { recording_key?: string; duration_sec?: number }
): Promise<{ status: string; ended_at: string; sessionId: string }> {
  return authedFetch(token, `/v1/live/sessions/${sessionId}/end`, {
    method: 'POST',
    body: JSON.stringify(payload)
  });
}

export async function getLiveSession(
  sessionId: string,
  role: 'host' | 'listener' = 'listener',
  token?: string | null
): Promise<LiveSessionCreateResponse> {
  const path = `/v1/live/sessions/${sessionId}?role=${role}`;
  if (token) {
    return authedFetch(token, path);
  }
  return apiFetch(path);
}
