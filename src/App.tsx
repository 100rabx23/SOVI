

import React, { useState, useEffect } from 'react';
import { LandingPage } from './pages/LandingPage';
import { SendPage } from './pages/SendPage';
import { ReceivePage } from './pages/ReceivePage';
import { HistoryPage } from './pages/HistoryPage';

type View = 'landing' | 'send' | 'receive' | 'history';

export default function App() {
  const [currentView, setCurrentView] = useState<View>('landing');

  // Initialize ggwave in the background on load (optional, but good for perceived perf)
  useEffect(() => {
    import('./audio/ggwaveManager').then(({ initGGWave }) => {
      initGGWave().catch(console.error);
    });
  }, []);

  return (
    <div className="w-full min-h-[100dvh] bg-[#020408] text-slate-200 flex flex-col font-sans overflow-x-hidden relative">
      <div className="fixed inset-0 opacity-20 pointer-events-none" style={{ backgroundImage: 'radial-gradient(#3b82f6 0.5px, transparent 0.5px)', backgroundSize: '24px 24px' }}></div>
      <div className="fixed -top-40 -left-40 w-96 h-96 bg-blue-600/10 rounded-full blur-[120px] pointer-events-none"></div>
      <div className="fixed -bottom-40 -right-40 w-96 h-96 bg-purple-600/10 rounded-full blur-[120px] pointer-events-none"></div>
      
      <div className="relative z-10 flex flex-col flex-1">
        {currentView === 'landing' && (
          <LandingPage 
            onStartSend={() => setCurrentView('send')} 
            onStartReceive={() => setCurrentView('receive')}
            onViewHistory={() => setCurrentView('history')}
          />
        )}
        
        {currentView === 'send' && (
          <SendPage onBack={() => setCurrentView('landing')} />
        )}

        {currentView === 'receive' && (
          <ReceivePage onBack={() => setCurrentView('landing')} />
        )}

        {currentView === 'history' && (
          <HistoryPage onBack={() => setCurrentView('landing')} />
        )}
      </div>
    </div>
  );
}



