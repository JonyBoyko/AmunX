import { useState } from 'react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Avatar, AvatarFallback } from './ui/avatar';
import { Mic, User, Play, Pause, MessageCircle, Share2, SkipBack, SkipForward } from 'lucide-react';
import { MiniWaveform } from './MiniWaveform';
import type { Episode } from '../App';

interface FeedScreenProps {
  isPro: boolean;
  onEpisodeClick: (episode: Episode) => void;
  onRecordClick: () => void;
  onProfileClick: () => void;
  onTopicClick: (topic: string) => void;
}

export function FeedScreen({ isPro, onEpisodeClick, onRecordClick, onProfileClick, onTopicClick }: FeedScreenProps) {
  const [playingId, setPlayingId] = useState<string | null>('1');

  const mockEpisodes: Episode[] = [
    {
      id: '1',
      tldr: 'Мої думки про нову AI-модель від OpenAI та як це вплине на розробку',
      duration: 60,
      currentTime: 0,
      isAnonymous: false,
      quality: 'Clean',
      mask: 'Off',
      topic: 'Tech',
      author: 'Олексій К.',
      reactions: [
        { emoji: '👍', count: 24 },
        { emoji: '🔥', count: 12 },
        { emoji: '💡', count: 8 },
      ],
      commentsCount: 5,
      timestamp: new Date(),
    },
    {
      id: '2',
      tldr: 'Чому я почав медитувати кожен ранок і як це змінило мій день',
      duration: 45,
      currentTime: 0,
      isAnonymous: true,
      quality: 'Raw',
      mask: 'Basic',
      topic: 'Health',
      reactions: [
        { emoji: '👍', count: 18 },
        { emoji: '❤️', count: 15 },
      ],
      commentsCount: 3,
      timestamp: new Date(),
    },
    {
      id: '3',
      tldr: '🔴 LIVE: Обговорення нового продукту',
      duration: 0,
      currentTime: 0,
      isAnonymous: false,
      quality: 'Clean',
      mask: 'Off',
      topic: 'Tech',
      author: 'Марія П.',
      reactions: [],
      commentsCount: 12,
      isLive: true,
      timestamp: new Date(),
    },
  ];

  return (
    <div className="min-h-screen bg-black pb-24">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-black/80 backdrop-blur-lg border-b border-zinc-900 p-4">
        <div className="flex items-center justify-between">
          <h1 className="text-white">Moweton</h1>
          <div className="flex gap-2">
            {isPro && (
              <Badge className="bg-gradient-to-r from-purple-600 to-pink-600">
                PRO
              </Badge>
            )}
            <Button variant="ghost" size="icon" onClick={onProfileClick}>
              <User className="w-5 h-5" />
            </Button>
          </div>
        </div>
      </div>

      {/* Feed */}
      <div className="space-y-0">
        {mockEpisodes.map((episode, index) => {
          const progressPercent = episode.isLive ? 0 : Math.random() * 100;
          return (
            <div
              key={episode.id}
              className="border-b border-border hover:bg-muted/5 transition-colors cursor-pointer"
              onClick={() => onEpisodeClick(episode)}
              style={{ borderWidth: '1px' }}
            >
              <div className="p-4 space-y-3">
                {/* Header */}
                <div className="flex items-start gap-3">
                  {/* Avatar with Progress Ring */}
                  <div className="relative flex-shrink-0">
                    <svg className="absolute -inset-[3px] w-[46px] h-[46px] -rotate-90">
                      <circle
                        cx="23"
                        cy="23"
                        r="21"
                        stroke="rgba(255, 255, 255, 0.06)"
                        strokeWidth="2"
                        fill="none"
                      />
                      {!episode.isLive && progressPercent > 0 && (
                        <circle
                          cx="23"
                          cy="23"
                          r="21"
                          stroke="var(--accent-primary)"
                          strokeWidth="2"
                          fill="none"
                          strokeDasharray={`${2 * Math.PI * 21}`}
                          strokeDashoffset={`${2 * Math.PI * 21 * (1 - progressPercent / 100)}`}
                          strokeLinecap="round"
                        />
                      )}
                    </svg>
                    <Avatar className="w-10 h-10">
                      <AvatarFallback className="bg-accent text-accent-foreground">
                        {episode.isAnonymous ? '?' : episode.author?.[0]}
                      </AvatarFallback>
                    </Avatar>
                  </div>

                  <div className="flex-1 min-w-0 space-y-2">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-foreground text-sm">
                        {episode.isAnonymous ? 'Анонім' : episode.author}
                      </span>
                      {episode.isAnonymous && (
                        <Badge 
                          variant="secondary" 
                          className="text-xs"
                          style={{ borderRadius: 'var(--radius-chip)' }}
                        >
                          ANON
                        </Badge>
                      )}
                      {episode.isLive && (
                        <Badge 
                          className="bg-destructive text-xs animate-pulse"
                          style={{ borderRadius: 'var(--radius-chip)' }}
                        >
                          🔴 LIVE
                        </Badge>
                      )}
                      <span className="text-muted-foreground text-xs">• 2 год</span>
                    </div>
                    <div className="flex gap-1.5 flex-wrap">
                      <Badge
                        variant="outline"
                        className="text-xs cursor-pointer hover:bg-muted"
                        style={{ borderRadius: 'var(--radius-chip)' }}
                        onClick={(e) => {
                          e.stopPropagation();
                          onTopicClick(episode.topic);
                        }}
                      >
                        {episode.topic}
                      </Badge>
                      <Badge 
                        variant="outline" 
                        className="text-xs"
                        style={{ borderRadius: 'var(--radius-chip)' }}
                      >
                        {episode.quality}
                      </Badge>
                      {episode.mask !== 'Off' && (
                        <Badge 
                          variant="outline" 
                          className="text-xs"
                          style={{ borderRadius: 'var(--radius-chip)' }}
                        >
                          {episode.mask}
                        </Badge>
                      )}
                    </div>
                  </div>
                </div>

                {/* TL;DR */}
                <p className="text-foreground text-sm leading-relaxed opacity-90">
                  {episode.tldr}
                </p>

                {/* Mini Waveform */}
                {!episode.isLive && (
                  <div className="px-3">
                    <MiniWaveform progress={progressPercent} />
                  </div>
                )}

                {/* Actions */}
                <div className="flex items-center justify-between pt-1">
                  <div className="flex gap-1.5">
                    {episode.reactions.map((reaction, idx) => (
                      <button
                        key={idx}
                        className="flex items-center gap-1 px-2.5 py-1 bg-muted/40 hover:bg-muted transition-colors text-xs"
                        style={{ borderRadius: 'var(--radius-chip)' }}
                        onClick={(e) => e.stopPropagation()}
                      >
                        <span className="text-sm">{reaction.emoji}</span>
                        <span className="text-muted-foreground">{reaction.count}</span>
                      </button>
                    ))}
                  </div>
                  <div className="flex gap-3 text-muted-foreground">
                    <button
                      className="flex items-center gap-1 hover:text-foreground transition-colors"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <MessageCircle className="w-4 h-4" />
                      <span className="text-xs">{episode.commentsCount}</span>
                    </button>
                    <button
                      className="hover:text-foreground transition-colors"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <Share2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Record FAB */}
      <button
        onClick={onRecordClick}
        className="fixed bottom-24 right-6 w-14 h-14 gradient-accent rounded-full flex items-center justify-center shadow-lg hover:scale-110 transition-transform z-50"
        style={{ borderRadius: 'var(--radius-fab)' }}
      >
        <Mic className="w-6 h-6 text-white" />
      </button>

      {/* Glassy Mini Player */}
      {playingId && (
        <div 
          className="fixed bottom-0 left-0 right-0 p-3 z-40"
          style={{
            background: 'rgba(17, 19, 24, 0.7)',
            backdropFilter: 'blur(8px)',
            WebkitBackdropFilter: 'blur(8px)',
            borderTop: '1px solid rgba(255, 255, 255, 0.06)',
          }}
        >
          <div className="max-w-2xl mx-auto">
            <div className="flex items-center gap-3">
              {/* Album Art / Avatar */}
              <div className="w-12 h-12 rounded-lg bg-muted flex items-center justify-center flex-shrink-0">
                <Avatar className="w-12 h-12">
                  <AvatarFallback className="bg-accent text-accent-foreground">
                    О
                  </AvatarFallback>
                </Avatar>
              </div>

              {/* Info & Waveform */}
              <div className="flex-1 min-w-0">
                <p className="text-sm text-foreground truncate">Мої думки про AI-модель</p>
                <div className="mt-1">
                  <MiniWaveform bars={30} progress={33} />
                </div>
              </div>

              {/* Controls */}
              <div className="flex items-center gap-1 flex-shrink-0">
                <Button
                  size="icon"
                  variant="ghost"
                  className="w-8 h-8"
                  onClick={(e) => {
                    e.stopPropagation();
                  }}
                >
                  <SkipBack className="w-4 h-4" />
                </Button>
                <Button
                  size="icon"
                  variant="ghost"
                  className="w-9 h-9 bg-accent hover:bg-accent/90"
                  onClick={() => setPlayingId(null)}
                >
                  <Pause className="w-5 h-5 text-accent-foreground" />
                </Button>
                <Button
                  size="icon"
                  variant="ghost"
                  className="w-8 h-8"
                  onClick={(e) => {
                    e.stopPropagation();
                  }}
                >
                  <SkipForward className="w-4 h-4" />
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
