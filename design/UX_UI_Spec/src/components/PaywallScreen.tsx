import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { ArrowLeft, Check, Crown, Sparkles } from 'lucide-react';

interface PaywallScreenProps {
  onUpgrade: () => void;
  onBack: () => void;
}

export function PaywallScreen({ onUpgrade, onBack }: PaywallScreenProps) {
  const features = [
    {
      icon: '🌍',
      title: 'Real-time captions & dubbing',
      description: 'Автоматичний переклад live на будь-яку мову',
    },
    {
      icon: '📝',
      title: 'Повні транскрипти та розділи',
      description: 'Текстова версія всіх епізодів з навігацією',
    },
    {
      icon: '🎙️',
      title: 'Studio voice mask',
      description: 'Покращене маскування голосу зі студійною якістю',
    },
    {
      icon: '⏱️',
      title: 'Довші Live епізоди',
      description: 'До 60 хвилин замість стандартних 10',
    },
    {
      icon: '📊',
      title: 'Розширена аналітика',
      description: 'Детальна статистика прослуховувань та реакцій',
    },
    {
      icon: '🎯',
      title: 'Пріоритетна підтримка',
      description: 'Швидка відповідь від команди підтримки',
    },
  ];

  return (
    <div className="min-h-screen bg-black">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-black/80 backdrop-blur-lg border-b border-zinc-900 p-4">
        <Button variant="ghost" size="icon" onClick={onBack}>
          <ArrowLeft className="w-5 h-5" />
        </Button>
      </div>

      <div className="p-6 space-y-8">
        {/* Hero */}
        <div className="text-center space-y-4">
          <div className="inline-flex w-20 h-20 bg-gradient-to-br from-purple-600 to-pink-600 rounded-3xl items-center justify-center">
            <Crown className="w-10 h-10 text-white" />
          </div>
          <div className="space-y-2">
            <h1 className="text-white text-3xl">
              Оновіться до Pro
            </h1>
            <p className="text-zinc-400">
              Отримайте всі можливості WalkCast
            </p>
          </div>
        </div>

        {/* Features */}
        <div className="space-y-4">
          {features.map((feature, idx) => (
            <div
              key={idx}
              className="bg-zinc-900 rounded-2xl p-4 flex gap-4"
            >
              <div className="text-3xl">{feature.icon}</div>
              <div className="flex-1 space-y-1">
                <h3 className="text-white">{feature.title}</h3>
                <p className="text-zinc-400 text-sm">{feature.description}</p>
              </div>
              <Check className="w-5 h-5 text-green-500 flex-shrink-0" />
            </div>
          ))}
        </div>

        {/* Pricing */}
        <div className="bg-gradient-to-br from-purple-900 to-pink-900 rounded-3xl p-6 space-y-4">
          <div className="flex items-baseline gap-2">
            <span className="text-white text-4xl">₴199</span>
            <span className="text-zinc-300">/місяць</span>
          </div>
          <ul className="space-y-2 text-sm">
            <li className="flex items-center gap-2 text-zinc-200">
              <Check className="w-4 h-4 text-green-400" />
              Перші 7 днів безкоштовно
            </li>
            <li className="flex items-center gap-2 text-zinc-200">
              <Check className="w-4 h-4 text-green-400" />
              Скасувати можна будь-коли
            </li>
            <li className="flex items-center gap-2 text-zinc-200">
              <Check className="w-4 h-4 text-green-400" />
              Всі майбутні функції включені
            </li>
          </ul>
          <Button
            onClick={onUpgrade}
            className="w-full bg-white text-black hover:bg-zinc-200 h-12"
          >
            <Sparkles className="w-4 h-4 mr-2" />
            Почати безкоштовний пробний період
          </Button>
        </div>

        {/* Demo */}
        <div className="text-center">
          <Button variant="ghost" className="text-zinc-400">
            Переглянути демо можливостей
          </Button>
        </div>

        {/* Legal */}
        <p className="text-center text-xs text-zinc-600">
          Підписка автоматично продовжується. Скасувати можна в будь-який час.
          <br />
          Дізнайтеся більше про{' '}
          <button className="text-zinc-500 underline">умови підписки</button>
        </p>
      </div>
    </div>
  );
}
