import { useState } from 'react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Avatar, AvatarFallback } from './ui/avatar';
import { Progress } from './ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { ScrollArea } from './ui/scroll-area';
import { ArrowLeft, Play, Pause, MoreVertical, MessageCircle, Lock, Heart, Share2, Copy, Check } from 'lucide-react';
import type { Episode } from '../App';

interface EpisodeDetailScreenProps {
  episode: Episode;
  isPro: boolean;
  onBack: () => void;
  onUpgrade: () => void;
  onCommentsClick: () => void;
}

export function EpisodeDetailScreen({ episode, isPro, onBack, onUpgrade, onCommentsClick }: EpisodeDetailScreenProps) {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [selectedText, setSelectedText] = useState('');
  const [showCopyButton, setShowCopyButton] = useState(false);
  const [copyPosition, setCopyPosition] = useState({ x: 0, y: 0 });
  const [copied, setCopied] = useState(false);

  const mockChapters = [
    { time: 0, title: 'Вступ' },
    { time: 15, title: 'Головна ідея' },
    { time: 35, title: 'Висновки' },
  ];

  const mockTranscriptLines = [
    { time: 0, text: 'Привіт! Сьогодні хочу поділитися думками про нову AI-модель від OpenAI.' },
    { time: 5, text: 'Це дійсно цікавий розвиток подій, який може суттєво вплинути на розробку.' },
    { time: 12, text: 'Я вважаю, що нам варто підготуватися до цих змін та зрозуміти, як це вплине на нашу роботу.' },
    { time: 18, text: 'По-перше, давайте подивимось на головні можливості цієї моделі.' },
    { time: 25, text: 'Вона може генерувати код, аналізувати великі обсяги даних, і навіть створювати контент.' },
    { time: 32, text: 'Але найважливіше - це розуміння контексту та здатність до аналізу.' },
    { time: 40, text: 'Я думаю, що це відкриває нові можливості для автоматизації багатьох процесів.' },
    { time: 48, text: 'Тож підсумовуючи, це великий крок вперед для всієї індустрії.' },
    { time: 55, text: 'Дякую, що слухали! Буду радий почути ваші думки в коментарях.' },
  ];

  const handleTextSelection = () => {
    const selection = window.getSelection();
    const text = selection?.toString().trim();
    
    if (text && text.length > 0) {
      setSelectedText(text);
      setShowCopyButton(true);
      setCopied(false);
      
      const range = selection?.getRangeAt(0);
      const rect = range?.getBoundingClientRect();
      if (rect) {
        setCopyPosition({
          x: rect.left + rect.width / 2,
          y: rect.top - 10,
        });
      }
    } else {
      setShowCopyButton(false);
    }
  };

  const handleCopyQuote = () => {
    navigator.clipboard.writeText(selectedText);
    setCopied(true);
    setTimeout(() => {
      setShowCopyButton(false);
      setCopied(false);
      window.getSelection()?.removeAllRanges();
    }, 1500);
  };

  return (
    <div className="min-h-screen bg-black pb-20">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-black/80 backdrop-blur-lg border-b border-zinc-900 p-4">
        <div className="flex items-center justify-between">
          <Button variant="ghost" size="icon" onClick={onBack}>
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <Button variant="ghost" size="icon">
            <MoreVertical className="w-5 h-5" />
          </Button>
        </div>
      </div>

      <div className="p-6 space-y-6 pb-24">
        {/* Player */}
        <div className="bg-gradient-to-br from-purple-900 to-pink-900 rounded-3xl p-8 space-y-6">
          <div className="flex items-center gap-4">
            <Avatar className="w-16 h-16">
              <AvatarFallback className="bg-purple-600 text-2xl">
                {episode.isAnonymous ? '?' : episode.author?.[0]}
              </AvatarFallback>
            </Avatar>
            <div className="flex-1">
              <p className="text-white">
                {episode.isAnonymous ? 'Анонімний автор' : episode.author}
              </p>
              <div className="flex gap-2 mt-1">
                <Badge variant="secondary" className="text-xs">
                  {episode.topic}
                </Badge>
                <Badge variant="secondary" className="text-xs">
                  {episode.quality}
                </Badge>
                {episode.mask !== 'Off' && (
                  <Badge variant="secondary" className="text-xs">
                    Mask: {episode.mask}
                  </Badge>
                )}
              </div>
            </div>
          </div>

          {/* Play Button */}
          <div className="flex justify-center">
            <button
              onClick={() => setIsPlaying(!isPlaying)}
              className="w-20 h-20 bg-white rounded-full flex items-center justify-center hover:scale-110 transition-transform"
            >
              {isPlaying ? (
                <Pause className="w-10 h-10 text-black" />
              ) : (
                <Play className="w-10 h-10 text-black ml-1" />
              )}
            </button>
          </div>

          {/* Progress */}
          <div className="space-y-2">
            <Progress value={(currentTime / episode.duration) * 100} className="h-2" />
            <div className="flex justify-between text-xs text-zinc-300">
              <span>00:{currentTime.toString().padStart(2, '0')}</span>
              <span>01:00</span>
            </div>
          </div>
        </div>

        {/* TL;DR */}
        <div className="bg-zinc-900 rounded-2xl p-6 space-y-2">
          <h3 className="text-zinc-400 text-sm">TL;DR</h3>
          <p className="text-white leading-relaxed">
            {episode.tldr}
          </p>
        </div>

        {/* Tabs: Chapters / Transcript */}
        <Tabs defaultValue="chapters" className="w-full">
          <TabsList className="w-full bg-zinc-900">
            <TabsTrigger value="chapters" className="flex-1">
              Розділи
            </TabsTrigger>
            <TabsTrigger value="transcript" className="flex-1">
              Транскрипт
              {!isPro && <Lock className="w-3 h-3 ml-1" />}
            </TabsTrigger>
          </TabsList>

          <TabsContent value="chapters" className="mt-4">
            {/* Horizontal Chapter Chips */}
            <ScrollArea className="w-full whitespace-nowrap pb-2">
              <div className="flex gap-2 px-1">
                {mockChapters.map((chapter, idx) => (
                  <button
                    key={idx}
                    className="inline-flex flex-col items-start gap-1 px-4 py-2.5 bg-muted hover:bg-muted/80 transition-colors"
                    style={{ borderRadius: 'var(--radius-chip)' }}
                    onClick={() => setCurrentTime(chapter.time)}
                  >
                    <span className="text-foreground text-sm whitespace-nowrap">
                      {chapter.title}
                    </span>
                    <span className="text-muted-foreground text-xs">
                      00:{chapter.time.toString().padStart(2, '0')}
                    </span>
                  </button>
                ))}
              </div>
            </ScrollArea>
          </TabsContent>

          <TabsContent value="transcript" className="mt-4">
            {isPro ? (
              <div className="relative">
                {/* Copy Quote Button */}
                {showCopyButton && (
                  <button
                    className="fixed z-50 px-3 py-1.5 bg-accent text-accent-foreground rounded-lg shadow-lg flex items-center gap-1.5 text-sm animate-in fade-in slide-in-from-bottom-2 duration-200"
                    style={{
                      left: `${copyPosition.x}px`,
                      top: `${copyPosition.y}px`,
                      transform: 'translate(-50%, -100%)',
                    }}
                    onClick={handleCopyQuote}
                  >
                    {copied ? (
                      <>
                        <Check className="w-3.5 h-3.5" />
                        Скопійовано
                      </>
                    ) : (
                      <>
                        <Copy className="w-3.5 h-3.5" />
                        Копіювати цитату
                      </>
                    )}
                  </button>
                )}

                {/* Transcript with Zebra Rows */}
                <div 
                  className="bg-card border border-border rounded-xl overflow-hidden"
                  onMouseUp={handleTextSelection}
                  onTouchEnd={handleTextSelection}
                >
                  {mockTranscriptLines.map((line, idx) => (
                    <div
                      key={idx}
                      className={`px-4 py-3 flex gap-4 ${
                        idx % 2 === 0 ? 'bg-transparent' : 'bg-muted/20'
                      }`}
                    >
                      <button
                        className="text-xs text-muted-foreground font-mono flex-shrink-0 hover:text-accent transition-colors"
                        onClick={() => setCurrentTime(line.time)}
                      >
                        00:{line.time.toString().padStart(2, '0')}
                      </button>
                      <p className="text-foreground leading-relaxed select-text">
                        {line.text}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <div className="bg-card border border-border rounded-xl p-8 text-center space-y-4">
                <Lock className="w-12 h-12 text-muted-foreground mx-auto" />
                <div className="space-y-2">
                  <h3 className="text-foreground">Транскрипти для Pro</h3>
                  <p className="text-muted-foreground text-sm">
                    Отримайте повний текст епізоду та розділи з Pro підпискою
                  </p>
                </div>
                <Button
                  onClick={onUpgrade}
                  className="gradient-accent"
                >
                  Оновити до Pro
                </Button>
              </div>
            )}
          </TabsContent>
        </Tabs>
      </div>

      {/* Sticky Actions Bar */}
      <div 
        className="fixed bottom-0 left-0 right-0 z-40 p-4 border-t border-border"
        style={{
          background: 'rgba(17, 19, 24, 0.85)',
          backdropFilter: 'blur(12px)',
          WebkitBackdropFilter: 'blur(12px)',
        }}
      >
        <div className="max-w-2xl mx-auto flex items-center justify-between gap-3">
          {/* Reactions */}
          <div className="flex gap-2">
            {['👍', '🔥', '💡'].map((emoji) => (
              <button
                key={emoji}
                className="w-10 h-10 bg-muted hover:bg-muted/80 flex items-center justify-center transition-colors"
                style={{ borderRadius: 'var(--radius-chip)' }}
              >
                <span className="text-xl">{emoji}</span>
              </button>
            ))}
          </div>

          {/* Action Buttons */}
          <div className="flex gap-2">
            <Button
              onClick={onCommentsClick}
              variant="outline"
              size="sm"
              className="gap-1.5"
            >
              <MessageCircle className="w-4 h-4" />
              <span className="hidden sm:inline">{episode.commentsCount}</span>
            </Button>
            <Button
              variant="outline"
              size="sm"
            >
              <Share2 className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
