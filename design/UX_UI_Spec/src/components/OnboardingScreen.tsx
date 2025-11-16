import { useState } from 'react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Mic, Send } from 'lucide-react';

interface OnboardingScreenProps {
  onLogin: () => void;
}

export function OnboardingScreen({ onLogin }: OnboardingScreenProps) {
  const [email, setEmail] = useState('');
  const [sent, setSent] = useState(false);

  const handleSend = () => {
    if (email) {
      setSent(true);
      setTimeout(() => {
        onLogin();
      }, 1500);
    }
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen px-6 bg-gradient-to-b from-black to-zinc-900">
      <div className="w-full max-w-md space-y-8">
        {/* Logo */}
        <div className="flex justify-center">
          <div className="w-20 h-20 bg-gradient-to-br from-purple-500 to-pink-500 rounded-3xl flex items-center justify-center">
            <Mic className="w-10 h-10 text-white" />
          </div>
        </div>

        {/* Pitch */}
        <div className="text-center space-y-3">
          <h1 className="text-white">WalkCast</h1>
          <p className="text-zinc-400">
            Ваш голосовий щоденник і walk-подкасти. Записуй 1-хв думки на ходу.
          </p>
        </div>

        {/* Email Form */}
        {!sent ? (
          <div className="space-y-4">
            <div className="space-y-2">
              <Input
                type="email"
                placeholder="your@email.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="bg-zinc-900 border-zinc-800 text-white placeholder:text-zinc-500"
              />
            </div>
            <Button 
              onClick={handleSend}
              className="w-full bg-purple-600 hover:bg-purple-700"
              disabled={!email}
            >
              <Send className="w-4 h-4 mr-2" />
              Надіслати лінк
            </Button>
          </div>
        ) : (
          <div className="p-4 bg-green-900/20 border border-green-800 rounded-lg text-center">
            <p className="text-green-400">
              Перевірте пошту! Лінк для входу надіслано.
            </p>
          </div>
        )}

        {/* Legal Footer */}
        <div className="text-center text-xs text-zinc-600">
          <p>
            Продовжуючи, ви погоджуєтесь з{' '}
            <button className="text-zinc-500 hover:text-zinc-400 underline">
              Умовами
            </button>{' '}
            та{' '}
            <button className="text-zinc-500 hover:text-zinc-400 underline">
              Політикою
            </button>
          </p>
        </div>
      </div>
    </div>
  );
}
