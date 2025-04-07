'use client';

import React, { createContext, useState, useContext, useMemo } from 'react';

interface PermissionLoadingContextProps {
  isLoadingPermissions: boolean;
  setIsLoadingPermissions: React.Dispatch<React.SetStateAction<boolean>>;
}

const PermissionLoadingContext = createContext<
  PermissionLoadingContextProps | undefined
>(undefined);

export const PermissionLoadingProvider: React.FC<React.PropsWithChildren> = ({
  children,
}) => {
  const [isLoadingPermissions, setIsLoadingPermissions] = useState(true); // 기본값 true (로딩 시작)

  const value = useMemo(
    () => ({ isLoadingPermissions, setIsLoadingPermissions }),
    [isLoadingPermissions],
  );

  return (
    <PermissionLoadingContext.Provider value={value}>
      {children}
    </PermissionLoadingContext.Provider>
  );
};

export const usePermissionLoading = (): PermissionLoadingContextProps => {
  const context = useContext(PermissionLoadingContext);
  if (context === undefined) {
    throw new Error(
      'usePermissionLoading must be used within a PermissionLoadingProvider',
    );
  }
  return context;
};
