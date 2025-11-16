import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Avatar, AvatarFallback } from './ui/avatar';
import { ArrowLeft, UserPlus, MessageCircle } from 'lucide-react';
import type { Episode } from '../App';

interface TopicScreenProps {
  topic: string;
  onBack: () => void;
  onEpisodeClick: (episode: Episode) => void;
}

export function TopicScreen({ topic, onBack, onEpisodeClick }: TopicScreenProps) {
  const mockEpisodes: Episode[] = [
    {
      id: '1',
      tldr: 'Мої думки про нову AI-модель від OpenAI',
      duration: 60,
      currentTime: 0,
      isAnonymous: false,
      quality: 'Clean',
      mask: 'Off',
      topic: 'Tech',
      author: 'Олексій К.',
      reactions: [{ emoji: '👍', count: 24 }],
      commentsCount: 5,
      timestamp: new Date(),
    },
    {
      id: '3',
      tldr: 'Як я почав використовувати Claude для кодування',
      duration: 55,
      currentTime: 0,
      isAnonymous: false,
      quality: 'Clean',
      mask: 'Basic',
      topic: 'Tech',
      author: 'Марія П.',
      reactions: [{ emoji: '🔥', count: 18 }],
      commentsCount: 7,
      timestamp: new Date(),
    },
  ];

  return (
    <div className="min-h-screen bg-black">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-black/80 backdrop-blur-lg border-b border-zinc-900 p-4">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={onBack}>
            <ArrowLeft className="w-5 h-5" />
          </Button>
        </div>
      </div>

      {/* Topic Header */}
      <div className="p-6 space-y-6">
        <div className="bg-gradient-to-br from-purple-900 to-pink-900 rounded-3xl p-8 space-y-4">
          <div className="w-16 h-16 bg-purple-600 rounded-2xl flex items-center justify-center text-3xl">
            💻
          </div>
          <div className="space-y-2">
            <h1 className="text-white text-3xl">{topic}</h1>
            <p className="text-zinc-300">
              Епізоди про технології, AI, розробку та інновації
            </p>
          </div>
          <div className="flex gap-3">
            <Button className="bg-white text-black hover:bg-zinc-200">
              <UserPlus className="w-4 h-4 mr-2" />
              Підписатися
            </Button>
            <Button variant="outline">
              Поділитися
            </Button>
          </div>
          <div className="flex gap-6 text-sm">
            <div>
              <p className="text-zinc-400">Епізодів</p>
              <p className="text-white">127</p>
            </div>
            <div>
              <p className="text-zinc-400">Підписників</p>
              <p className="text-white">2.4K</p>
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="flex gap-2">
          <Badge className="bg-purple-600 cursor-pointer">Нові</Badge>
          <Badge variant="outline" className="cursor-pointer">Популярні</Badge>
          <Badge variant="outline" className="cursor-pointer">Рекомендовані</Badge>
        </div>

        {/* Episodes */}
        <div className="space-y-4">
          {mockEpisodes.map((episode) => (
            <div
              key={episode.id}
              onClick={() => onEpisodeClick(episode)}
              className="bg-zinc-900 rounded-2xl p-4 space-y-3 hover:bg-zinc-800 transition-colors cursor-pointer"
            >
              <div className="flex items-start gap-3">
                <Avatar className="w-10 h-10">
                  <AvatarFallback className="bg-purple-600">
                    {episode.author?.[0]}
                  </AvatarFallback>
                </Avatar>
                <div className="flex-1 space-y-2">
                  <div className="flex items-center gap-2">
                    <span className="text-white text-sm">{episode.author}</span>
                    <span className="text-zinc-600 text-xs">• 2 год тому</span>
                  </div>
                  <p className="text-zinc-300 text-sm leading-relaxed">
                    {episode.tldr}
                  </p>
                  <div className="flex items-center justify-between pt-2">
                    <div className="flex gap-3">
                      {episode.reactions.map((reaction, idx) => (
                        <span key={idx} className="text-sm text-zinc-400">
                          {reaction.emoji} {reaction.count}
                        </span>
                      ))}
                    </div>
                    <div className="flex items-center gap-1 text-zinc-400">
                      <MessageCircle className="w-4 h-4" />
                      <span className="text-xs">{episode.commentsCount}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
