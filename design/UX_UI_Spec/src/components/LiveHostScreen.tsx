import { useState, useEffect } from 'react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Switch } from './ui/switch';
import { Label } from './ui/label';
import { PhoneOff, Mic, MicOff, Radio, Users } from 'lucide-react';
import type { Episode } from '../App';

interface LiveHostScreenProps {
  isPro: boolean;
  onEnd: (episode: Episode) => void;
  onUpgrade: () => void;
}

export function LiveHostScreen({ isPro, onEnd, onUpgrade }: LiveHostScreenProps) {
  const [duration, setDuration] = useState(0);
  const [isMuted, setIsMuted] = useState(false);
  const [translateEnabled, setTranslateEnabled] = useState(false);
  const [listeners, setListeners] = useState(12);
  const [reactions, setReactions] = useState<{ emoji: string; id: number }[]>([]);
  const [selectedLanguages, setSelectedLanguages] = useState<string[]>([]);

  useEffect(() => {
    const interval = setInterval(() => {
      setDuration(prev => prev + 1);
      // Simulate listener changes
      setListeners(prev => Math.max(1, prev + Math.floor(Math.random() * 3) - 1));
      
      // Simulate reactions
      if (Math.random() > 0.7) {
        const emojis = ['👍', '🔥', '💡', '❤️'];
        setReactions(prev => [...prev, { 
          emoji: emojis[Math.floor(Math.random() * emojis.length)], 
          id: Date.now() 
        }]);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    // Remove old reactions
    const timeout = setTimeout(() => {
      setReactions(prev => prev.slice(-5));
    }, 3000);
    return () => clearTimeout(timeout);
  }, [reactions]);

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const handleEnd = () => {
    const episode: Episode = {
      id: Date.now().toString(),
      tldr: 'Live епізод завершено',
      duration,
      currentTime: 0,
      isAnonymous: false,
      quality: 'Clean',
      mask: 'Off',
      topic: 'Tech',
      author: 'Ви',
      reactions: [],
      commentsCount: 0,
      timestamp: new Date(),
    };
    onEnd(episode);
  };

  const toggleLanguage = (lang: string) => {
    if (!isPro) {
      onUpgrade();
      return;
    }
    setSelectedLanguages(prev =>
      prev.includes(lang)
        ? prev.filter(l => l !== lang)
        : prev.length < 2
        ? [...prev, lang]
        : prev
    );
  };

  return (
    <div className="min-h-screen bg-black flex flex-col">
      {/* Header */}
      <div className="p-4 border-b border-zinc-900">
        <div className="flex items-center gap-3">
          <div className="w-3 h-3 bg-red-600 rounded-full animate-pulse" />
          <Badge className="bg-red-600">LIVE</Badge>
          <span className="text-white text-2xl font-mono">{formatTime(duration)}</span>
        </div>
      </div>

      {/* Main Area */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 space-y-8">
        {/* Listener Count */}
        <div className="bg-zinc-900 rounded-2xl px-6 py-3 flex items-center gap-3">
          <Users className="w-5 h-5 text-purple-400" />
          <span className="text-white">{listeners} слухачів</span>
        </div>

        {/* Reactions Overlay */}
        <div className="fixed inset-0 pointer-events-none flex items-end justify-center pb-40">
          <div className="relative w-full max-w-md h-64">
            {reactions.map((reaction) => (
              <div
                key={reaction.id}
                className="absolute bottom-0 text-4xl animate-float"
                style={{
                  left: `${Math.random() * 80 + 10}%`,
                  animation: 'float 3s ease-out forwards',
                }}
              >
                {reaction.emoji}
              </div>
            ))}
          </div>
        </div>

        {/* Translate Control (Pro) */}
        {isPro ? (
          <div className="w-full max-w-md bg-zinc-900 rounded-2xl p-6 space-y-4">
            <div className="flex items-center justify-between">
              <Label htmlFor="translate" className="text-white">
                Live Translate
              </Label>
              <Switch
                id="translate"
                checked={translateEnabled}
                onCheckedChange={setTranslateEnabled}
              />
            </div>
            {translateEnabled && (
              <div className="space-y-3">
                <p className="text-sm text-zinc-400">
                  Виберіть мови (макс 2):
                </p>
                <div className="flex flex-wrap gap-2">
                  {['EN', 'PL', 'DE', 'FR'].map((lang) => (
                    <Badge
                      key={lang}
                      variant={selectedLanguages.includes(lang) ? 'default' : 'outline'}
                      className={`cursor-pointer ${
                        selectedLanguages.includes(lang) ? 'bg-purple-600' : ''
                      }`}
                      onClick={() => toggleLanguage(lang)}
                    >
                      {lang}
                    </Badge>
                  ))}
                </div>
                {selectedLanguages.length > 0 && (
                  <p className="text-xs text-zinc-500">
                    Активні мови: {selectedLanguages.join(', ')}
                  </p>
                )}
              </div>
            )}
          </div>
        ) : (
          <div className="w-full max-w-md bg-zinc-900 rounded-2xl p-6 text-center space-y-3">
            <p className="text-white text-sm">
              Live Translate доступно для Pro
            </p>
            <Button
              onClick={onUpgrade}
              size="sm"
              className="bg-gradient-to-r from-purple-600 to-pink-600"
            >
              Оновити до Pro
            </Button>
          </div>
        )}

        {/* Controls */}
        <div className="flex gap-4">
          <Button
            size="icon"
            variant={isMuted ? 'default' : 'outline'}
            className={`w-16 h-16 rounded-full ${
              isMuted ? 'bg-red-600' : ''
            }`}
            onClick={() => setIsMuted(!isMuted)}
          >
            {isMuted ? <MicOff className="w-6 h-6" /> : <Mic className="w-6 h-6" />}
          </Button>
          <Button
            size="icon"
            className="w-16 h-16 rounded-full bg-red-600 hover:bg-red-700"
            onClick={handleEnd}
          >
            <PhoneOff className="w-6 h-6" />
          </Button>
        </div>

        {/* Chat Preview */}
        <div className="w-full max-w-md bg-zinc-900 rounded-2xl p-4 space-y-2 max-h-32 overflow-y-auto">
          <p className="text-xs text-zinc-500">Чат:</p>
          <div className="space-y-1 text-sm">
            <p className="text-zinc-400">
              <span className="text-purple-400">Марія:</span> Чудова тема! 👏
            </p>
            <p className="text-zinc-400">
              <span className="text-purple-400">Олексій:</span> Питання про AI?
            </p>
          </div>
        </div>
      </div>

      <style>{`
        @keyframes float {
          0% {
            transform: translateY(0) scale(1);
            opacity: 1;
          }
          100% {
            transform: translateY(-300px) scale(1.5);
            opacity: 0;
          }
        }
      `}</style>
    </div>
  );
}
