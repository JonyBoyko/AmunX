import React from 'react';
import { create } from 'zustand';

export type User = {
  id: string;
  email: string;
  is_pro: boolean;
};

export type SessionState = {
  isLoading: boolean;
  isAuthenticated: boolean;
  token: string | null;
  user: User | null;
  hydrate: () => void;
  setToken: (token: string | null) => void;
  clearSession: () => void;
};

const useSessionStore = create<SessionState>((set) => ({
  isLoading: true,
  isAuthenticated: false,
  token: null,
  user: null,
  hydrate: () => {
    // TODO: Fetch user from AsyncStorage or API
    set({ isLoading: false });
  },
  setToken: (token) => {
    // TODO: Fetch user profile if token exists
    const mockUser: User | null = token
      ? { id: '1', email: 'user@amunx.app', is_pro: false }
      : null;
    set({
      token,
      user: mockUser,
      isAuthenticated: Boolean(token),
      isLoading: false,
    });
  },
  clearSession: () =>
    set({
      token: null,
      user: null,
      isAuthenticated: false,
    }),
}));

const SessionContext = React.createContext<typeof useSessionStore | null>(null);

export const SessionProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return <SessionContext.Provider value={useSessionStore}>{children}</SessionContext.Provider>;
};

export const useSession = () => {
  const ctx = React.useContext(SessionContext);
  if (!ctx) {
    throw new Error('useSession must be used within SessionProvider');
  }
  return ctx();
};

