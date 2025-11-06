import { apiClient } from './client';

export interface Circle {
  id: string;
  owner_id: string;
  name: string;
  description: string;
  is_local: boolean;
  city?: string;
  country?: string;
  member_count: number;
  user_role?: string;
  created_at: string;
}

export interface CirclePost {
  id: string;
  owner: {
    id: string;
    display_name: string;
    avatar_url?: string;
  };
  title?: string;
  duration_sec: number;
  audio_url: string;
  reply_count: number;
  created_at: string;
}

export interface CircleFeedResponse {
  posts: CirclePost[];
  next_cursor?: string;
  has_more: boolean;
}

export interface CreateCircleParams {
  name: string;
  description?: string;
  is_local?: boolean;
  city?: string;
  country?: string;
}

export interface PostToCircleParams {
  audio_id: string;
  title?: string;
  description?: string;
}

export interface ReplyToPostParams {
  parent_audio_id: string;
  s3_key: string;
  duration_sec: number;
  title?: string;
}

async function getCircle(id: string): Promise<Circle> {
  return apiClient<Circle>({
    method: 'GET',
    endpoint: `/circles/${id}`,
  });
}

async function getCircleFeed(id: string, cursor?: string): Promise<CircleFeedResponse> {
  const url = `/circles/${id}/feed${cursor ? `?cursor=${cursor}` : ''}`;
  return apiClient<CircleFeedResponse>({
    method: 'GET',
    endpoint: url,
  });
}

async function createCircle(params: CreateCircleParams): Promise<Circle> {
  return apiClient<Circle>({
    method: 'POST',
    endpoint: '/circles',
    body: params,
  });
}

async function joinCircle(id: string): Promise<void> {
  return apiClient<void>({
    method: 'POST',
    endpoint: `/circles/${id}/join`,
  });
}

async function leaveCircle(id: string): Promise<void> {
  return apiClient<void>({
    method: 'POST',
    endpoint: `/circles/${id}/leave`,
  });
}

async function postToCircle(id: string, params: PostToCircleParams): Promise<void> {
  return apiClient<void>({
    method: 'POST',
    endpoint: `/circles/${id}/posts`,
    body: params,
  });
}

async function replyToPost(id: string, params: ReplyToPostParams): Promise<any> {
  return apiClient<any>({
    method: 'POST',
    endpoint: `/circles/${id}/replies`,
    body: params,
  });
}

export const circlesAPI = {
  getCircle,
  getCircleFeed,
  createCircle,
  joinCircle,
  leaveCircle,
  postToCircle,
  replyToPost,
};

