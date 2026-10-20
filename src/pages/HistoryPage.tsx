import React, { useState, useEffect, useRef } from 'react';
import { ArrowLeft, Trash2, Volume2, Mic, Clock3, Play, Square, History, Inbox, Send } from 'lucide-react';
import { motion } from 'motion/react';
import { exportMessageAsWav } from '../audio/ggwaveEncoder';

interface HistoryPageProps { onBack: () => void; }

export function HistoryPage({ onBack }: HistoryPageProps) {
  const [history, setHistory] = useState<any[]>([]);
  const [playingIndex, setPlayingIndex] = useState<number | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    const historyStr = localStorage.getItem('soundmesh_history');
    if (historyStr) {
      try { setHistory(JSON.parse(historyStr).reverse()); } catch { setHistory([]); }
    }
    return () => { if (audioRef.current) audioRef.current.pause(); };
  }, []);

  const clearHistory = () => {
    if (confirm('Are you sure you want to clear all history?')) { localStorage.removeItem('soundmesh_history'); setHistory([]); }
  };

  const togglePlayAudio = async (message: string, index: number) => {
    if (playingIndex === index && audioRef.current) { audioRef.current.pause(); audioRef.current = null; setPlayingIndex(null); return; }
    if (audioRef.current) audioRef.current.pause();
    try {
      setPlayingIndex(index);
      const packet = `SM1|${Math.floor(Math.random() * 1000)}|${message}`;
      const blob = await exportMessageAsWav(packet);
      const url = URL.createObjectURL(blob);
      const audio = new Audio(url); audioRef.current = audio;
      audio.onended = () => { setPlayingIndex(null); audioRef.current = null; URL.revokeObjectURL(url); };
      await audio.play();
    } catch (e) { console.error(e); setPlayingIndex(null); }
  };

  return (
    <div className="min-h-[100dvh] w-full overflow-hidden bg-[#f7f7f2] text-[#20251a]">
      <header className="sticky top-0 z-30 border-b border-[#657047]/10 bg-[#f7f7f2]/80 px-4 py-4 backdrop-blur-2xl sm:px-8">
        <div className="mx-auto flex max-w-5xl items-center justify-between">
          <button onClick={onBack} className="grid h-10 w-10 place-items-center rounded-xl border border-[#657047]/15 bg-white/70 text-[#68734d] transition hover:-translate-x-0.5 hover:bg-white"><ArrowLeft size={19} /></button>
          <div className="text-center"><div className="text-[10px] font-extrabold uppercase tracking-[.25em] text-[#7b826f]">SoundMesh</div><div className="mt-0.5 text-sm font-black tracking-tight">Transmission history</div></div>
          {history.length > 0 ? <button onClick={clearHistory} className="grid h-10 w-10 place-items-center rounded-xl border border-red-200 bg-red-50 text-red-500 transition hover:bg-red-100"><Trash2 size={18} /></button> : <div className="h-10 w-10" />}
        </div>
      </header>

      <main className="relative mx-auto min-h-[calc(100dvh-73px)] max-w-5xl px-4 py-8 sm:px-8">
        <div className="pointer-events-none absolute -right-32 top-0 h-80 w-80 rounded-full bg-[#c4ccb0]/25 blur-3xl" />
        <div className="relative">
          <div className="mb-8 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
            <div>
              <div className="inline-flex items-center gap-2 text-[10px] font-extrabold uppercase tracking-[.22em] text-[#7b826f]"><History size={14} /> Local archive</div>
              <h1 className="mt-2 text-4xl font-black tracking-[-.055em] sm:text-5xl">Your transmissions.</h1>
              <p className="mt-2 text-sm text-[#858a7c]">{history.length} {history.length === 1 ? 'record' : 'records'} stored on this device.</p>
            </div>
          </div>

          {history.length === 0 ? (
            <div className="flex min-h-[48vh] flex-col items-center justify-center rounded-[2rem] border border-dashed border-[#657047]/15 bg-white/50 p-10 text-center">
              <div className="grid h-16 w-16 place-items-center rounded-2xl bg-[#e8ebde] text-[#77805d]"><Clock3 size={28} /></div>
              <div className="mt-5 text-lg font-black tracking-tight">Nothing here yet</div>
              <p className="mt-2 max-w-sm text-sm leading-6 text-[#92978a]">Send or receive a SoundMesh message and your local activity will appear here.</p>
            </div>
          ) : (
            <div className="space-y-3">
              {history.map((item, i) => (
                <motion.div key={i} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: Math.min(i * .04, .3) }}
                  className="group rounded-[1.5rem] border border-[#657047]/10 bg-white/75 p-4 shadow-sm backdrop-blur-xl transition duration-300 hover:-translate-y-0.5 hover:shadow-[0_18px_50px_rgba(70,77,48,.09)] sm:p-5">
                  <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
                    <div className={`grid h-12 w-12 shrink-0 place-items-center rounded-2xl ${item.type === 'sent' ? 'bg-[#e5e9d8] text-[#667149]' : 'bg-[#edf0e6] text-[#7b8463]'}`}>
                      {item.type === 'sent' ? <Send size={19} /> : <Inbox size={19} />}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="text-[9px] font-extrabold uppercase tracking-[.18em] text-[#68734d]">{item.type === 'sent' ? 'Transmitted' : 'Received'}</span>
                        <span className="h-1 w-1 rounded-full bg-[#b3b7aa]" />
                        <span className="text-[9px] font-bold uppercase tracking-widest text-[#a0a397]">{new Date(item.timestamp).toLocaleString()}</span>
                      </div>
                      <div className="mt-2 break-words text-base font-semibold leading-6 text-[#303625] sm:text-lg">{item.message}</div>
                    </div>
                    {item.type === 'sent' && (
                      <button onClick={() => togglePlayAudio(item.message, i)} className={`grid h-11 w-11 shrink-0 place-items-center rounded-xl border transition ${playingIndex === i ? 'border-[#657047]/20 bg-[#e5e9d8] text-[#667149]' : 'border-[#657047]/10 bg-[#f6f7f1] text-[#89907e] hover:bg-[#e9ecdf] hover:text-[#667149]'}`}>
                        {playingIndex === i ? <Square size={16} fill="currentColor" /> : <Play size={16} fill="currentColor" />}
                      </button>
                    )}
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
