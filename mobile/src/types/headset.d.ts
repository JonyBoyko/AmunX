import type { NativeModule } from "react-native";

declare module "react-native" {
  interface NativeModulesStatic {
    HeadsetDetector?: HeadsetDetectorModule;
  }
}

type HeadsetDetectorModule = NativeModule & {
  getCurrentState?: () => Promise<{ connected: boolean }>;
};
