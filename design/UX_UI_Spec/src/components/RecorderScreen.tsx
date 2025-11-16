import { useState, useEffect } from 'react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { ArrowLeft, Mic, Square, Radio, Activity } from 'lucide-react';
import { Switch } from './ui/switch';
import { Label } from './ui/label';

interface RecorderScreenProps {
  onRecordComplete: (data: {
    duration: number;
    isPublic: boolean;
    quality: 'Raw' | 'Clean';
    mask: 'Off' | 'Basic' | 'Studio';
  }) => void;
  onGoLive: () => void;
  onBack: () => void;
}

export function RecorderScreen({ onRecordComplete, onGoLive, onBack }: RecorderScreenProps) {
  const [isRecording, setIsRecording] = useState(false);
  const [duration, setDuration] = useState(0);
  const [isPublic, setIsPublic] = useState(true);
  const [quality, setQuality] = useState<'Raw' | 'Clean'>('Clean');
  const [mask, setMask] = useState<'Off' | 'Basic' | 'Studio'>('Off');
  const [audioLevel, setAudioLevel] = useState(0);

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isRecording) {
      interval = setInterval(() => {
        setDuration(prev => prev + 1);
        setAudioLevel(Math.random() * 100);
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isRecording]);

  const handleRecord = () => {
    if (!isRecording) {
      setIsRecording(true);
      setDuration(0);
    } else {
      setIsRecording(false);
      onRecordComplete({ duration, isPublic, quality, mask });
    }
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const progressPercent = Math.min((duration / 60) * 100, 100);

  return (
    <div className="min-h-screen bg-black flex flex-col">
      {/* Header */}
      <div className="p-4 flex items-center justify-between border-b border-zinc-900">
        <Button variant="ghost" size="icon" onClick={onBack}>
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <Badge 
          variant={isPublic ? "default" : "secondary"} 
          className={isPublic ? "bg-accent" : "bg-secondary"}
          style={{ borderRadius: 'var(--radius-chip)' }}
        >
          {isPublic ? 'PUBLIC' : 'ANON'}
        </Badge>
      </div>

      {/* Main Recording Area */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 space-y-8">
        {/* Audio Level Indicator */}
        {isRecording && (
          <div className="flex items-center gap-2">
            <Activity className="w-5 h-5 text-green-500" />
            <div className="flex gap-1">
              {[...Array(10)].map((_, i) => (
                <div
                  key={i}
                  className="w-1 h-8 bg-zinc-800 rounded-full"
                  style={{
                    backgroundColor: i < audioLevel / 10 ? '#22c55e' : '#27272a',
                  }}
                />
              ))}
            </div>
          </div>
        )}

        {/* Timer */}
        <div className="text-center space-y-2">
          <div className="text-6xl font-mono text-white">
            {formatTime(duration)}
          </div>
          {duration >= 60 && (
            <p className="text-zinc-500 text-sm">
              Рекомендовано: 1 хвилина
            </p>
          )}
        </div>

        {/* Record Button with Progress Ring */}
        <div className="relative flex items-center justify-center">
          {/* Progress Ring */}
          <svg className="absolute w-[76px] h-[76px] -rotate-90" style={{ filter: 'drop-shadow(0 0 8px rgba(106, 166, 255, 0.3))' }}>
            <circle
              cx="38"
              cy="38"
              r="34"
              stroke="rgba(255, 255, 255, 0.06)"
              strokeWidth="3"
              fill="none"
            />
            {isRecording && (
              <circle
                cx="38"
                cy="38"
                r="34"
                stroke="var(--accent-primary)"
                strokeWidth="3"
                fill="none"
                strokeDasharray={`${2 * Math.PI * 34}`}
                strokeDashoffset={`${2 * Math.PI * 34 * (1 - progressPercent / 100)}`}
                strokeLinecap="round"
                style={{ transition: 'stroke-dashoffset 0.3s ease' }}
              />
            )}
          </svg>
          
          {/* FAB Button */}
          <button
            onClick={handleRecord}
            className={`relative w-[60px] h-[60px] rounded-full flex items-center justify-center transition-all shadow-lg ${
              isRecording
                ? 'bg-destructive hover:bg-destructive/90'
                : 'bg-accent hover:bg-accent/90'
            }`}
          >
            {isRecording ? (
              <Square className="w-6 h-6 text-white fill-white" />
            ) : (
              <Mic className="w-7 h-7 text-white" />
            )}
          </button>
        </div>

        {/* Controls */}
        <div className="w-full max-w-sm space-y-4 bg-zinc-900 rounded-2xl p-6">
          {/* Public/Anonymous */}
          <div className="flex items-center justify-between">
            <Label htmlFor="public" className="text-zinc-400">
              Публічно
            </Label>
            <Switch
              id="public"
              checked={isPublic}
              onCheckedChange={setIsPublic}
              disabled={isRecording}
            />
          </div>

          {/* Quality */}
          <div className="flex items-center justify-between">
            <Label className="text-zinc-400">Якість</Label>
            <div className="flex gap-2">
              <Button
                size="sm"
                variant={quality === 'Raw' ? 'default' : 'outline'}
                onClick={() => !isRecording && setQuality('Raw')}
                disabled={isRecording}
                className={quality === 'Raw' ? 'bg-purple-600' : ''}
              >
                Raw
              </Button>
              <Button
                size="sm"
                variant={quality === 'Clean' ? 'default' : 'outline'}
                onClick={() => !isRecording && setQuality('Clean')}
                disabled={isRecording}
                className={quality === 'Clean' ? 'bg-purple-600' : ''}
              >
                Clean
              </Button>
            </div>
          </div>

          {/* Voice Mask */}
          <div className="flex items-center justify-between">
            <Label className="text-zinc-400">Маскування</Label>
            <div className="flex gap-2">
              <Button
                size="sm"
                variant={mask === 'Off' ? 'default' : 'outline'}
                onClick={() => !isRecording && setMask('Off')}
                disabled={isRecording}
                className={mask === 'Off' ? 'bg-purple-600' : ''}
              >
                Off
              </Button>
              <Button
                size="sm"
                variant={mask === 'Basic' ? 'default' : 'outline'}
                onClick={() => !isRecording && setMask('Basic')}
                disabled={isRecording}
                className={mask === 'Basic' ? 'bg-purple-600' : ''}
              >
                Basic
              </Button>
              <Button
                size="sm"
                variant={mask === 'Studio' ? 'default' : 'outline'}
                onClick={() => !isRecording && setMask('Studio')}
                disabled={isRecording}
                className={mask === 'Studio' ? 'bg-purple-600' : ''}
              >
                Studio
              </Button>
            </div>
          </div>
        </div>

        {/* Live Button */}
        <Button
          onClick={onGoLive}
          variant="outline"
          className="border-pink-600 text-pink-600 hover:bg-pink-600 hover:text-white"
        >
          <Radio className="w-4 h-4 mr-2" />
          Почати Live
        </Button>
      </div>
    </div>
  );
}
