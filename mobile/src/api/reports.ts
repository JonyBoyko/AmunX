import { authedFetch } from './client';

export type ReportPayload = {
  object_ref: string;
  reason?: string;
};

export async function submitReport(token: string, payload: ReportPayload): Promise<void> {
  await authedFetch<{ report: unknown }>(token, '/v1/reports', {
    method: 'POST',
    body: JSON.stringify(payload)
  });
}
