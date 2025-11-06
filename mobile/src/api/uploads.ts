import { apiClient } from './client';

export interface PresignedUploadResponse {
  url: string;
  fields: Record<string, string>;
  s3_key: string;
  expires_at: string;
}

interface GetPresignedUrlParams {
  mime: string;
  filename: string;
}

async function getPresignedUrl(params: GetPresignedUrlParams): Promise<PresignedUploadResponse> {
  return apiClient<PresignedUploadResponse>({
    method: 'POST',
    endpoint: '/uploads/presign',
    body: params,
  });
}

export const uploadsAPI = {
  getPresignedUrl,
};

