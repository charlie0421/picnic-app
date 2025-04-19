'use client';

import React, { createContext, useContext, useState, ReactNode, useCallback } from 'react';
import { PortalType } from '../utils/enums';

interface NavigationState {
  currentScreen: ReactNode | null;
  showTopMenu: boolean;
  showPortal: boolean;
  currentPortalType: PortalType;
}

interface NavigationContextProps {
  navigationState: NavigationState;
  setCurrentScreen: (screen: ReactNode) => void;
  setShowTopMenu: (show: boolean) => void;
  setShowPortal: (show: boolean) => void;
  setCurrentPortalType: (type: PortalType) => void;
}

const NavigationContext = createContext<NavigationContextProps | undefined>(undefined);

export const NavigationProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [navigationState, setNavigationState] = useState<NavigationState>({
    currentScreen: null,
    showTopMenu: true,
    showPortal: true,
    currentPortalType: PortalType.VOTE,
  });

  const setCurrentScreen = useCallback((screen: ReactNode) => {
    setNavigationState((prev) => ({ ...prev, currentScreen: screen }));
  }, []);

  const setShowTopMenu = useCallback((show: boolean) => {
    setNavigationState((prev) => ({ ...prev, showTopMenu: show }));
  }, []);

  const setShowPortal = useCallback((show: boolean) => {
    setNavigationState((prev) => ({ ...prev, showPortal: show }));
  }, []);

  const setCurrentPortalType = useCallback((type: PortalType) => {
    setNavigationState((prev) => ({ ...prev, currentPortalType: type }));
  }, []);

  return (
    <NavigationContext.Provider
      value={{
        navigationState,
        setCurrentScreen,
        setShowTopMenu,
        setShowPortal,
        setCurrentPortalType,
      }}
    >
      {children}
    </NavigationContext.Provider>
  );
};

export const useNavigation = () => {
  const context = useContext(NavigationContext);
  if (context === undefined) {
    throw new Error('useNavigation must be used within a NavigationProvider');
  }
  return context;
}; 