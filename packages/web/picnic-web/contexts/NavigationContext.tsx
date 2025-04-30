'use client';

import React, {
  createContext,
  useContext,
  useState,
  ReactNode,
  useCallback,
} from 'react';
import { PortalType } from '../utils/enums';

interface NavigationState {
  currentScreen: ReactNode | null;
  currentPortalType: PortalType;
}

interface NavigationContextProps {
  navigationState: NavigationState;
  setCurrentScreen: (screen: ReactNode) => void;
  setCurrentPortalType: (type: PortalType) => void;
}

const NavigationContext = createContext<NavigationContextProps | undefined>(
  undefined,
);

export const NavigationProvider: React.FC<{ children: ReactNode }> = ({
  children,
}) => {
  const [navigationState, setNavigationState] = useState<NavigationState>({
    currentScreen: null,
    currentPortalType: PortalType.VOTE,
  });

  const setCurrentScreen = useCallback((screen: ReactNode) => {
    setNavigationState((prev) => ({ ...prev, currentScreen: screen }));
  }, []);

  const setCurrentPortalType = useCallback((type: PortalType) => {
    setNavigationState((prev) => ({ ...prev, currentPortalType: type }));
  }, []);

  return (
    <NavigationContext.Provider
      value={{
        navigationState,
        setCurrentScreen,
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
