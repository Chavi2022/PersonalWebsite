import React, { createContext, useContext } from 'react';

type MigrationContextType = {
  [key: string]: any;
};
const MigrationContext = createContext<MigrationContextType | undefined>(undefined);

export const useMigrationContext = () => {
  const context = useContext(MigrationContext);
  if (context === undefined) {
    throw new Error('useMigrationContext must be used within a MigrationProvider');
  }
  return context;
};
export const MigrationProvider: React.FC<{children: React.ReactNode, value: MigrationContextType}> = ({children, value}) => {
  return (
    <MigrationContext.Provider value={value}>
      {children}
    </MigrationContext.Provider>
  );
};
