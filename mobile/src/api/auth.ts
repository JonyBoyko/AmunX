import { apiFetch } from './client';

type MagicLinkResponse = {
  token: string;
};

export async function requestMagicLink(email: string): Promise<void> {
  await apiFetch<void>('/v1/auth/magiclink', {
    method: 'POST',
    body: JSON.stringify({ email })
  });
}

export async function verifyMagicLink(token: string): Promise<MagicLinkResponse> {
  return apiFetch<MagicLinkResponse>('/v1/auth/magiclink/verify', {
    method: 'POST',
    body: JSON.stringify({ token })
  });
}

