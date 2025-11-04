import { useEffect, useState } from 'react';
import { NativeEventEmitter, NativeModules } from 'react-native';

const { HeadsetDetector } = NativeModules;

type HeadsetState = {
  connected: boolean;
};

export function useHeadset(): HeadsetState {
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    if (!HeadsetDetector) {
      return;
    }
    const emitter = new NativeEventEmitter(HeadsetDetector);
    const subscription = emitter.addListener('HeadsetState', (state: HeadsetState) => {
      setConnected(state.connected);
    });
    HeadsetDetector.getCurrentState?.().then((state: HeadsetState) => {
      setConnected(state.connected);
    });
    return () => subscription.remove();
  }, []);

  return { connected };
}

