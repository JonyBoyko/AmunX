import { useState } from 'react';
import { Button } from './ui/button';
import { Avatar, AvatarFallback } from './ui/avatar';
import { Input } from './ui/input';
import { ArrowLeft, Send } from 'lucide-react';
import type { Episode } from '../App';

interface CommentsScreenProps {
  episode: Episode;
  onBack: () => void;
}

export function CommentsScreen({ episode, onBack }: CommentsScreenProps) {
  const [comment, setComment] = useState('');

  const quickTemplates = [
    '🤔 Питання...',
    '💬 Розкажи продовження завтра',
    '👏 Дякую за епізод!',
  ];

  const mockComments = [
    {
      id: '1',
      author: 'Марія К.',
      isAnonymous: false,
      text: 'Дуже цікаво! А що ти думаєш про GPT-4?',
      timestamp: '5 хв тому',
    },
    {
      id: '2',
      author: 'Анонім',
      isAnonymous: true,
      text: 'Розкажи більше про практичне застосування',
      timestamp: '12 хв тому',
    },
  ];

  return (
    <div className="min-h-screen bg-black flex flex-col">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-black/80 backdrop-blur-lg border-b border-zinc-900 p-4">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={onBack}>
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div className="flex-1">
            <h2 className="text-white">Коментарі</h2>
            <p className="text-zinc-500 text-sm">{mockComments.length} коментарів</p>
          </div>
        </div>
      </div>

      {/* Quick Templates */}
      <div className="p-4 border-b border-zinc-900">
        <div className="flex gap-2 overflow-x-auto">
          {quickTemplates.map((template, idx) => (
            <button
              key={idx}
              onClick={() => setComment(template)}
              className="px-4 py-2 bg-zinc-900 hover:bg-zinc-800 rounded-full text-sm text-zinc-300 whitespace-nowrap transition-colors"
            >
              {template}
            </button>
          ))}
        </div>
      </div>

      {/* Comments List */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {mockComments.map((comment) => (
          <div key={comment.id} className="bg-zinc-900 rounded-2xl p-4 space-y-3">
            <div className="flex items-start gap-3">
              <Avatar className="w-10 h-10">
                <AvatarFallback className="bg-purple-600">
                  {comment.isAnonymous ? '?' : comment.author[0]}
                </AvatarFallback>
              </Avatar>
              <div className="flex-1 space-y-1">
                <div className="flex items-center gap-2">
                  <span className="text-white text-sm">
                    {comment.isAnonymous ? 'Анонім' : comment.author}
                  </span>
                  <span className="text-zinc-600 text-xs">
                    {comment.timestamp}
                  </span>
                </div>
                <p className="text-zinc-300 text-sm leading-relaxed">
                  {comment.text}
                </p>
                <div className="flex gap-4 pt-1">
                  <button className="text-xs text-zinc-500 hover:text-zinc-400">
                    Відповісти
                  </button>
                  <button className="text-xs text-zinc-500 hover:text-zinc-400">
                    Репорт
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Input */}
      <div className="sticky bottom-0 bg-black border-t border-zinc-900 p-4">
        <div className="flex gap-2">
          <Input
            placeholder="Ваш коментар..."
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            className="bg-zinc-900 border-zinc-800 text-white"
          />
          <Button
            size="icon"
            disabled={!comment}
            className="bg-purple-600 hover:bg-purple-700"
          >
            <Send className="w-4 h-4" />
          </Button>
        </div>
      </div>
    </div>
  );
}
