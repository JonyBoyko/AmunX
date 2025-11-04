import { API_BASE } from './config';

export type Topic = {
  id: string;
  name: string;
  description: string;
  slug: string;
  created_at: string;
  follower_count?: number;
  episode_count?: number;
  is_following?: boolean;
};

export type TopicsResponse = {
  topics: Topic[];
  total: number;
};

/**
 * List all topics
 */
export async function listTopics(token?: string | null): Promise<TopicsResponse> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${API_BASE}/topics`, { headers });

  if (!response.ok) {
    throw new Error(`Failed to fetch topics: ${response.statusText}`);
  }

  return response.json();
}

/**
 * Get topic by ID
 */
export async function getTopic(topicId: string, token?: string | null): Promise<Topic> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${API_BASE}/topics/${topicId}`, { headers });

  if (!response.ok) {
    throw new Error(`Failed to fetch topic: ${response.statusText}`);
  }

  return response.json();
}

/**
 * Follow a topic
 */
export async function followTopic(token: string, topicId: string): Promise<void> {
  const response = await fetch(`${API_BASE}/topics/${topicId}/follow`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to follow topic: ${response.statusText}`);
  }
}

/**
 * Unfollow a topic
 */
export async function unfollowTopic(token: string, topicId: string): Promise<void> {
  const response = await fetch(`${API_BASE}/topics/${topicId}/follow`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to unfollow topic: ${response.statusText}`);
  }
}

