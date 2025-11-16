import { useState } from 'react';
import { OnboardingScreen } from './components/OnboardingScreen';
import { RecorderScreen } from './components/RecorderScreen';
import { PublishScreen } from './components/PublishScreen';
import { FeedScreen } from './components/FeedScreen';
import { EpisodeDetailScreen } from './components/EpisodeDetailScreen';
import { LiveHostScreen } from './components/LiveHostScreen';
import { LiveListenerScreen } from './components/LiveListenerScreen';
import { ProfileScreen } from './components/ProfileScreen';
import { PaywallScreen } from './components/PaywallScreen';
import { CommentsScreen } from './components/CommentsScreen';
import { TopicScreen } from './components/TopicScreen';

type Screen = 
  | 'ONB-001'
  | 'RCRD-001'
  | 'PUB-001'
  | 'FEED-001'
  | 'EP-001'
  | 'CMT-001'
  | 'TOP-001'
  | 'LIVE-H-001'
  | 'LIVE-L-001'
  | 'PRF-001'
  | 'PAY-001';

export interface Episode {
  id: string;
  title?: string;
  tldr: string;
  duration: number;
  currentTime: number;
  isAnonymous: boolean;
  quality: 'Raw' | 'Clean';
  mask: 'Off' | 'Basic' | 'Studio';
  topic: string;
  author?: string;
  avatar?: string;
  reactions: { emoji: string; count: number }[];
  commentsCount: number;
  isLive?: boolean;
  timestamp: Date;
}

export interface AppState {
  currentScreen: Screen;
  isPro: boolean;
  isLoggedIn: boolean;
  recordingData?: {
    duration: number;
    isPublic: boolean;
    quality: 'Raw' | 'Clean';
    mask: 'Off' | 'Basic' | 'Studio';
  };
  selectedEpisode?: Episode;
  selectedTopic?: string;
}

export default function App() {
  const [appState, setAppState] = useState<AppState>({
    currentScreen: 'ONB-001',
    isPro: false,
    isLoggedIn: false,
  });

  const navigateTo = (screen: Screen, data?: Partial<AppState>) => {
    setAppState(prev => ({
      ...prev,
      currentScreen: screen,
      ...data,
    }));
  };

  const upgradeToPro = () => {
    setAppState(prev => ({ ...prev, isPro: true, currentScreen: 'FEED-001' }));
  };

  const renderScreen = () => {
    switch (appState.currentScreen) {
      case 'ONB-001':
        return (
          <OnboardingScreen
            onLogin={() => navigateTo('FEED-001', { isLoggedIn: true })}
          />
        );
      case 'RCRD-001':
        return (
          <RecorderScreen
            onRecordComplete={(recordingData) => 
              navigateTo('PUB-001', { recordingData })
            }
            onGoLive={() => navigateTo('LIVE-H-001')}
            onBack={() => navigateTo('FEED-001')}
          />
        );
      case 'PUB-001':
        return (
          <PublishScreen
            recordingData={appState.recordingData}
            onPublish={() => navigateTo('FEED-001')}
            onUndo={() => navigateTo('FEED-001')}
          />
        );
      case 'FEED-001':
        return (
          <FeedScreen
            isPro={appState.isPro}
            onEpisodeClick={(episode) => 
              navigateTo('EP-001', { selectedEpisode: episode })
            }
            onRecordClick={() => navigateTo('RCRD-001')}
            onProfileClick={() => navigateTo('PRF-001')}
            onTopicClick={(topic) => 
              navigateTo('TOP-001', { selectedTopic: topic })
            }
          />
        );
      case 'EP-001':
        return (
          <EpisodeDetailScreen
            episode={appState.selectedEpisode!}
            isPro={appState.isPro}
            onBack={() => navigateTo('FEED-001')}
            onUpgrade={() => navigateTo('PAY-001')}
            onCommentsClick={() => navigateTo('CMT-001')}
          />
        );
      case 'CMT-001':
        return (
          <CommentsScreen
            episode={appState.selectedEpisode!}
            onBack={() => navigateTo('EP-001')}
          />
        );
      case 'TOP-001':
        return (
          <TopicScreen
            topic={appState.selectedTopic || 'Tech'}
            onBack={() => navigateTo('FEED-001')}
            onEpisodeClick={(episode) => 
              navigateTo('EP-001', { selectedEpisode: episode })
            }
          />
        );
      case 'LIVE-H-001':
        return (
          <LiveHostScreen
            isPro={appState.isPro}
            onEnd={(episode) => navigateTo('EP-001', { selectedEpisode: episode })}
            onUpgrade={() => navigateTo('PAY-001')}
          />
        );
      case 'LIVE-L-001':
        return (
          <LiveListenerScreen
            isPro={appState.isPro}
            onLeave={() => navigateTo('FEED-001')}
            onUpgrade={() => navigateTo('PAY-001')}
          />
        );
      case 'PRF-001':
        return (
          <ProfileScreen
            isPro={appState.isPro}
            onBack={() => navigateTo('FEED-001')}
            onUpgrade={() => navigateTo('PAY-001')}
          />
        );
      case 'PAY-001':
        return (
          <PaywallScreen
            onUpgrade={upgradeToPro}
            onBack={() => navigateTo(appState.isLoggedIn ? 'FEED-001' : 'ONB-001')}
          />
        );
      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-black text-white">
      {renderScreen()}
    </div>
  );
}
