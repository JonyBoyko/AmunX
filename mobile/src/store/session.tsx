import React from 'react';
import { create } from 'zustand';

export type SessionState = {
  isLoading: boolean;
  isAuthenticated: boolean;
  token: string | null;
  hydrate: () => void;
  setToken: (token: string | null) => void;
};

const useSessionStore = create<SessionState>((set) => ({
  isLoading: true,
  isAuthenticated: false,
  token: null,
  hydrate: () => {
    set({ isLoading: false });
  },
  setToken: (token) =>
    set({
      token,
      isAuthenticated: Boolean(token),
      isLoading: false
    })
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

