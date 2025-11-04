# Mobile — Expo Dev Client Setup

This project now ships with an Expo-compatible configuration so you can build a
custom development client and test on a real device quickly.

## Prerequisites

- Node 18+
- `npm` 9+ (or `yarn`)
- Android Studio / Xcode installed if you plan to build locally
- [Expo CLI](https://docs.expo.dev/more/expo-cli/) (`npx expo ...` works without a global install)

## Install dependencies

```sh
cd mobile
npm install --legacy-peer-deps
```

## Create native projects (first run)

Expo dev client relies on native projects. Generate them once via:

```sh
npx expo prebuild
```

This will produce fresh `android/` and `ios/` folders with the required LiveKit
and WebRTC integration.

## Build a dev client

### Android (local)

```sh
npx expo run:android
```

### iOS (local)

```sh
npx expo run:ios
```

You can also build on EAS:

```sh
npx expo upload:android   # or expo upload:ios
```

## Launch on device

Start the Metro bundler in dev-client mode:

```sh
npx expo start --dev-client
```

Scan the QR code with the Expo Go app (Android) or the Camera app (iOS) and open
the custom development client you built. The Live Host / Listener screens use
`LiveKitRoom`, so audio will start streaming as soon as the room connects.

## Environment

- `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` should point to your
  self-hosted or Cloud instance (configure them in the backend `.env`). Ensure
  the backend is reachable from your phone (same Wi-Fi or via tunnelling).

Once the API is running, use the `Host Live` and `Join Live` buttons on the home
screen to exercise the full flow. The new Expo setup eliminates the need to
manually configure native projects – rebuild the dev client whenever native
dependencies change.*** End Patch
