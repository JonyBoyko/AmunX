import { useInfiniteQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { authedFetch, apiFetch } from '@api/client';
import type { FeedResponse, FeedEpisode } from '@api/feed';
import { reactToEpisode } from '@api/episodes';

type UseFeedOptions = {
  token?: string | null;
  topicId?: string;
  authorId?: string;
};

export function useFeed({ token, topicId, authorId }: UseFeedOptions = {}) {
  const queryClient = useQueryClient();

  // Infinite query for feed
  const query = useInfiniteQuery({
    queryKey: ['feed', { token, topicId, authorId }],
    queryFn: async ({ pageParam }) => {
      let url = '/v1/episodes?limit=20';
      
      if (topicId) url += `&topic=${topicId}`;
      if (authorId) url += `&author=${authorId}`;
      if (pageParam) url += `&after=${pageParam}`;

      if (token) {
        return authedFetch<FeedResponse>(token, url);
      }
      return apiFetch<FeedResponse>(url);
    },
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (lastPage) => {
      // Backend returns episodes sorted by published_at DESC
      // Use last episode's published_at as cursor for next page
      const lastEpisode = lastPage.items[lastPage.items.length - 1];
      return lastEpisode?.published_at || undefined;
    },
    // Refetch on window focus and every 15 seconds
    refetchInterval: 15000,
    refetchOnWindowFocus: true,
    staleTime: 10000, // Consider data stale after 10s
  });

  // Mutation for reactions
  const reactMutation = useMutation({
    mutationFn: async ({ episodeId, type }: { episodeId: string; type: string }) => {
      if (!token) throw new Error('Authentication required');
      return reactToEpisode(token, episodeId, type);
    },
    onSuccess: () => {
      // Refetch feed to update reaction counts
      queryClient.invalidateQueries({ queryKey: ['feed'] });
    },
  });

  // Flatten pages into single array
  const episodes = query.data?.pages.flatMap((page) => page.items) ?? [];

  return {
    episodes,
    isLoading: query.isLoading,
    isError: query.isError,
    error: query.error,
    refetch: query.refetch,
    fetchNextPage: query.fetchNextPage,
    hasNextPage: query.hasNextPage,
    isFetchingNextPage: query.isFetchingNextPage,
    react: reactMutation.mutate,
    isReacting: reactMutation.isPending,
  };
}

// Hook for single episode
export function useEpisode(id: string) {
  return useInfiniteQuery({
    queryKey: ['episode', id],
    queryFn: async () => {
      const episode = await apiFetch<FeedEpisode>(`/v1/episodes/${id}`);
      return { items: [episode] };
    },
    initialPageParam: undefined,
    getNextPageParam: () => undefined,
  });
}

