import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Avatar, AvatarFallback } from './ui/avatar';
import { Switch } from './ui/switch';
import { Label } from './ui/label';
import { ArrowLeft, Crown, Bell, Info, LogOut } from 'lucide-react';

interface ProfileScreenProps {
  isPro: boolean;
  onBack: () => void;
  onUpgrade: () => void;
}

export function ProfileScreen({ isPro, onBack, onUpgrade }: ProfileScreenProps) {
  return (
    <div className="min-h-screen bg-black">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-black/80 backdrop-blur-lg border-b border-zinc-900 p-4">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={onBack}>
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <h2 className="text-white">Профіль</h2>
        </div>
      </div>

      <div className="p-6 space-y-6">
        {/* Profile Header */}
        <div className="bg-gradient-to-br from-purple-900 to-pink-900 rounded-3xl p-6 space-y-4">
          <div className="flex items-center gap-4">
            <Avatar className="w-20 h-20">
              <AvatarFallback className="bg-purple-600 text-2xl">
                О
              </AvatarFallback>
            </Avatar>
            <div className="flex-1">
              <div className="flex items-center gap-2">
                <h2 className="text-white text-xl">Олексій</h2>
                {isPro && (
                  <Badge className="bg-gradient-to-r from-yellow-500 to-orange-500">
                    <Crown className="w-3 h-3 mr-1" />
                    PRO
                  </Badge>
                )}
              </div>
              <p className="text-zinc-300 text-sm">@oleksiy_tech</p>
            </div>
          </div>
          {!isPro && (
            <Button
              onClick={onUpgrade}
              className="w-full bg-gradient-to-r from-purple-600 to-pink-600"
            >
              <Crown className="w-4 h-4 mr-2" />
              Оновити до Pro
            </Button>
          )}
        </div>

        {/* Settings */}
        <div className="space-y-4">
          <h3 className="text-zinc-400 text-sm">Налаштування запису</h3>
          
          <div className="bg-zinc-900 rounded-2xl p-4 space-y-4">
            {/* Public by Default */}
            <div className="flex items-center justify-between">
              <Label htmlFor="public-default" className="text-white">
                Публічно за замовчуванням
              </Label>
              <Switch id="public-default" defaultChecked />
            </div>

            {/* Default Quality */}
            <div className="space-y-2">
              <Label className="text-white text-sm">Якість за замовчуванням</Label>
              <div className="flex gap-2">
                <Button size="sm" variant="outline">Raw</Button>
                <Button size="sm" className="bg-purple-600">Clean</Button>
              </div>
            </div>

            {/* Default Mask */}
            <div className="space-y-2">
              <Label className="text-white text-sm">Маскування за замовчуванням</Label>
              <div className="flex gap-2">
                <Button size="sm" className="bg-purple-600">Off</Button>
                <Button size="sm" variant="outline">Basic</Button>
                <Button size="sm" variant="outline">Studio</Button>
              </div>
            </div>
          </div>
        </div>

        {/* Notifications */}
        <div className="space-y-4">
          <h3 className="text-zinc-400 text-sm">Нотифікації</h3>
          
          <div className="bg-zinc-900 rounded-2xl p-4 space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Bell className="w-5 h-5 text-zinc-400" />
                <Label className="text-white">Нові епізоди в темах</Label>
              </div>
              <Switch defaultChecked />
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Bell className="w-5 h-5 text-zinc-400" />
                <Label className="text-white">Відповіді на епізоди</Label>
              </div>
              <Switch defaultChecked />
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Bell className="w-5 h-5 text-zinc-400" />
                <Label className="text-white">Денний дайджест</Label>
              </div>
              <Switch />
            </div>
          </div>
        </div>

        {/* Other */}
        <div className="space-y-2">
          <Button variant="ghost" className="w-full justify-start text-white">
            <Info className="w-5 h-5 mr-3" />
            Про додаток
          </Button>
          <Button variant="ghost" className="w-full justify-start text-red-500">
            <LogOut className="w-5 h-5 mr-3" />
            Вийти
          </Button>
        </div>

        {/* Version */}
        <p className="text-center text-xs text-zinc-600">
          Moweton v1.0.0
        </p>
      </div>
    </div>
  );
}
