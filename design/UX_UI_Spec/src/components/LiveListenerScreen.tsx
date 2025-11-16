import { useState } from 'react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { PhoneOff, Subtitles } from 'lucide-react';

interface LiveListenerScreenProps {
  isPro: boolean;
  onLeave: () => void;
  onUpgrade: () => void;
}

export function LiveListenerScreen({ isPro, onLeave, onUpgrade }: LiveListenerScreenProps) {
  const [selectedTrack, setSelectedTrack] = useState<'original' | 'en' | 'pl'>('original');

  const handleTrackChange = (track: 'original' | 'en' | 'pl') => {
    if (track !== 'original' && !isPro) {
      onUpgrade();
      return;
    }
    setSelectedTrack(track);
  };

  return (
    <div className="min-h-screen bg-black flex flex-col">
      {/* Header */}
      <div className="p-4 border-b border-zinc-900">
        <div className="flex items-center gap-3">
          <div className="w-3 h-3 bg-red-600 rounded-full animate-pulse" />
          <Badge className="bg-red-600">LIVE</Badge>
          <span className="text-zinc-400 text-sm">Слухаєте live епізод</span>
        </div>
      </div>

      {/* Main Area */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 space-y-8">
        {/* Audio Track Selector */}
        <div className="w-full max-w-md space-y-4">
          <div className="bg-zinc-900 rounded-2xl p-6 space-y-4">
            <div className="flex items-center gap-2">
              <Subtitles className="w-5 h-5 text-purple-400" />
              <Label className="text-white">Аудіо трек</Label>
            </div>
            <div className="flex gap-2">
              <Button
                variant={selectedTrack === 'original' ? 'default' : 'outline'}
                className={selectedTrack === 'original' ? 'bg-purple-600' : ''}
                onClick={() => handleTrackChange('original')}
              >
                Оригінал
              </Button>
              <Button
                variant={selectedTrack === 'en' ? 'default' : 'outline'}
                className={selectedTrack === 'en' ? 'bg-purple-600' : ''}
                onClick={() => handleTrackChange('en')}
              >
                EN {!isPro && '🔒'}
              </Button>
              <Button
                variant={selectedTrack === 'pl' ? 'default' : 'outline'}
                className={selectedTrack === 'pl' ? 'bg-purple-600' : ''}
                onClick={() => handleTrackChange('pl')}
              >
                PL {!isPro && '🔒'}
              </Button>
            </div>
            {!isPro && (
              <p className="text-xs text-zinc-500 text-center">
                Переклад доступний для Pro підписників
              </p>
            )}
          </div>

          {/* Reactions */}
          <div className="bg-zinc-900 rounded-2xl p-6">
            <p className="text-sm text-zinc-400 mb-3">Швидкі реакції:</p>
            <div className="flex gap-3 justify-center">
              {['👍', '🔥', '💡', '❤️', '🎯'].map((emoji) => (
                <button
                  key={emoji}
                  className="text-3xl hover:scale-125 transition-transform"
                >
                  {emoji}
                </button>
              ))}
            </div>
          </div>

          {/* Chat */}
          <div className="bg-zinc-900 rounded-2xl p-4 space-y-2 max-h-48 overflow-y-auto">
            <p className="text-xs text-zinc-500">Чат:</p>
            <div className="space-y-2 text-sm">
              <p className="text-zinc-400">
                <span className="text-purple-400">Марія:</span> Чудова тема! 👏
              </p>
              <p className="text-zinc-400">
                <span className="text-purple-400">Олексій:</span> Питання про AI?
              </p>
              <p className="text-zinc-400">
                <span className="text-purple-400">Анна:</span> Дуже цікаво!
              </p>
            </div>
          </div>
        </div>

        {/* Leave Button */}
        <Button
          size="icon"
          className="w-16 h-16 rounded-full bg-red-600 hover:bg-red-700"
          onClick={onLeave}
        >
          <PhoneOff className="w-6 h-6" />
        </Button>
      </div>
    </div>
  );
}

function Label({ children, className }: { children: React.ReactNode; className?: string }) {
  return <label className={className}>{children}</label>;
}
