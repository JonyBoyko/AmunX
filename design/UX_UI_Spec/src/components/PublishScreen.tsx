import { useState, useEffect } from 'react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Progress } from './ui/progress';
import { Badge } from './ui/badge';

interface PublishScreenProps {
  recordingData?: {
    duration: number;
    isPublic: boolean;
    quality: 'Raw' | 'Clean';
    mask: 'Off' | 'Basic' | 'Studio';
  };
  onPublish: () => void;
  onUndo: () => void;
}

export function PublishScreen({ recordingData, onPublish, onUndo }: PublishScreenProps) {
  const [countdown, setCountdown] = useState(10);
  const [title, setTitle] = useState('');
  const [topic, setTopic] = useState('');
  const [toastVisible, setToastVisible] = useState(false);

  useEffect(() => {
    // Animate toast in
    setTimeout(() => setToastVisible(true), 50);

    const interval = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          clearInterval(interval);
          onPublish();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [onPublish]);

  const progress = ((10 - countdown) / 10) * 100;

  const topics = ['Tech', 'Life', 'Work', 'Travel', 'Health', 'Random'];

  return (
    <div className="min-h-screen bg-black flex items-center justify-center px-6">
      <div className="w-full max-w-md space-y-6">
        {/* Floating Undo Toast */}
        <div 
          className={`fixed top-6 left-1/2 -translate-x-1/2 w-[80%] max-w-md transition-all duration-[220ms] ease-out ${
            toastVisible ? 'opacity-100 translate-y-0' : 'opacity-0 -translate-y-4'
          }`}
          style={{
            animation: toastVisible ? 'slideIn 220ms ease-out' : 'none'
          }}
        >
          <div className="bg-card border border-border rounded-xl shadow-2xl overflow-hidden">
            {/* Progress Line */}
            <div className="h-[2px] bg-muted relative overflow-hidden">
              <div 
                className="h-full bg-accent transition-all duration-1000 ease-linear"
                style={{ width: `${progress}%` }}
              />
            </div>
            
            {/* Content */}
            <div className="p-4 flex items-center justify-between gap-3">
              <div className="flex-1">
                <p className="text-foreground">
                  Публікуємо за <span className="font-bold">{countdown} с</span>
                </p>
              </div>
              <Button
                onClick={onUndo}
                size="sm"
                variant="outline"
                className="border-accent text-accent hover:bg-accent hover:text-accent-foreground"
              >
                Скасувати
              </Button>
            </div>
          </div>
        </div>

        {/* Recording Info */}
        <div className="bg-zinc-900 rounded-2xl p-6 space-y-4">
          <div className="flex gap-2">
            <Badge variant="secondary">{recordingData?.quality}</Badge>
            {recordingData?.mask !== 'Off' && (
              <Badge variant="secondary">Mask: {recordingData?.mask}</Badge>
            )}
            <Badge variant={recordingData?.isPublic ? 'default' : 'secondary'}>
              {recordingData?.isPublic ? 'Публічно' : 'Приватно'}
            </Badge>
          </div>

          {/* Optional Title */}
          <div className="space-y-2">
            <label className="text-sm text-zinc-400">
              Заголовок (необов'язково)
            </label>
            <Input
              placeholder="Швидкий заголовок..."
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="bg-zinc-800 border-zinc-700 text-white"
            />
          </div>

          {/* Topic Selection */}
          <div className="space-y-2">
            <label className="text-sm text-zinc-400">
              Тема
            </label>
            <div className="flex flex-wrap gap-2">
              {topics.map((t) => (
                <Badge
                  key={t}
                  variant={topic === t ? 'default' : 'outline'}
                  className={`cursor-pointer ${
                    topic === t ? 'bg-purple-600' : 'hover:bg-zinc-800'
                  }`}
                  onClick={() => setTopic(t)}
                >
                  {t}
                </Badge>
              ))}
            </div>
          </div>
        </div>

        {/* Info */}
        <p className="text-center text-xs text-zinc-600">
          Після публікації ваш епізод з'явиться в стрічці
        </p>
      </div>
    </div>
  );
}
