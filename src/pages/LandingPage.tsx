import React from 'react';
import { motion } from 'motion/react';
import { Radio, Mic, Volume2, Zap, WifiOff, History, ArrowUpRight, ShieldCheck, Sparkles } from 'lucide-react';

interface LandingPageProps {
  onStartSend: () => void;
  onStartReceive: () => void;
  onViewHistory: () => void;
}

export function LandingPage({ onStartSend, onStartReceive, onViewHistory }: LandingPageProps) {
  return (
    <div className="min-h-[100dvh] w-full overflow-hidden bg-[#f7f7f2] text-[#20251a] selection:bg-[#6f7950]/20">
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="absolute -top-40 -right-40 h-[32rem] w-[32rem] rounded-full bg-[#9ca77a]/20 blur-3xl" />
        <div className="absolute top-[35%] -left-48 h-[28rem] w-[28rem] rounded-full bg-[#d9ddc7]/60 blur-3xl" />
        <div className="absolute bottom-[-14rem] right-[15%] h-[30rem] w-[30rem] rounded-full bg-[#b8c09a]/20 blur-3xl" />
        <div className="absolute inset-0 opacity-[0.12]" style={{ backgroundImage: 'linear-gradient(#6f7950 1px, transparent 1px), linear-gradient(90deg, #6f7950 1px, transparent 1px)', backgroundSize: '56px 56px' }} />
      </div>

      <header className="sticky top-0 z-30 border-b border-[#68734d]/10 bg-[#f7f7f2]/75 px-4 py-4 backdrop-blur-2xl sm:px-8 lg:px-12">
        <div className="mx-auto flex max-w-7xl items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="grid h-10 w-10 place-items-center rounded-2xl bg-[#657047] text-white shadow-[0_12px_30px_rgba(101,112,71,.25)]">
              <Radio size={19} />
            </div>
            <div>
              <div className="text-lg font-black tracking-[-0.04em]">SO<span className="text-[#707b50]">VI</span></div>
              <div className="text-[9px] font-bold uppercase tracking-[0.28em] text-[#7d836f]">Acoustic data layer</div>
            </div>
          </div>
          <div className="hidden items-center gap-2 rounded-full border border-[#657047]/15 bg-white/60 px-3 py-2 text-[10px] font-bold uppercase tracking-[0.2em] text-[#68734d] sm:flex">
            <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-[#7b8a4f]" />
            SM1 · Beta
          </div>
        </div>
      </header>

      <main className="relative z-10 mx-auto max-w-7xl px-4 pb-16 pt-10 sm:px-8 sm:pt-16 lg:px-12 lg:pt-20">
        <section className="grid items-center gap-10 lg:grid-cols-[1.1fr_.9fr]">
          <div>
            <motion.div initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: .7 }}
              className="mb-6 inline-flex items-center gap-2 rounded-full border border-[#657047]/15 bg-white/70 px-4 py-2 text-[10px] font-extrabold uppercase tracking-[.22em] text-[#68734d] shadow-sm">
              <Sparkles size={14} />
              Private. Local. Acoustic.
            </motion.div>

            <motion.h1 initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: .8, delay: .08 }}
              className="max-w-4xl text-5xl font-black leading-[.94] tracking-[-.065em] sm:text-7xl lg:text-[6.4rem]">
              Send data.
              <br />
              <span className="text-[#6c774d]">Through sound.</span>
            </motion.h1>

            <motion.p initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: .8, delay: .16 }}
              className="mt-7 max-w-2xl text-base leading-7 text-[#6f7467] sm:text-lg">
              A beautifully simple acoustic channel for short messages between nearby devices — using speakers and microphones instead of Wi-Fi or Bluetooth.
            </motion.p>

            <motion.div initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: .8, delay: .24 }}
              className="mt-9 flex flex-col gap-3 sm:flex-row">
              <button onClick={onStartSend}
                className="group inline-flex items-center justify-center gap-3 rounded-2xl bg-[#667149] px-7 py-4 text-sm font-extrabold uppercase tracking-[.13em] text-white shadow-[0_18px_40px_rgba(102,113,73,.25)] transition duration-300 hover:-translate-y-1 hover:bg-[#59633e] active:scale-[.98]">
                <Volume2 size={20} />
                Send message
                <ArrowUpRight size={17} className="transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
              </button>
              <button onClick={onStartReceive}
                className="inline-flex items-center justify-center gap-3 rounded-2xl border border-[#657047]/20 bg-white/75 px-7 py-4 text-sm font-extrabold uppercase tracking-[.13em] text-[#38402b] shadow-sm transition duration-300 hover:-translate-y-1 hover:bg-white active:scale-[.98]">
                <Mic size={20} />
                Receive
              </button>
            </motion.div>

            <div className="mt-9 flex flex-wrap gap-2">
              {[
                [WifiOff, 'No network'],
                [Radio, 'Acoustic transfer'],
                [ShieldCheck, 'Local first']
              ].map(([Icon, label]: any) => (
                <div key={label} className="flex items-center gap-2 rounded-full border border-[#657047]/10 bg-white/60 px-3.5 py-2 text-[10px] font-bold uppercase tracking-[.16em] text-[#7a806f]">
                  <Icon size={13} className="text-[#71804c]" /> {label}
                </div>
              ))}
            </div>
          </div>

          <motion.div initial={{ opacity: 0, scale: .94 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: .9, delay: .15 }}
            className="relative mx-auto w-full max-w-[32rem]">
            <div className="absolute -inset-6 rounded-[3rem] bg-[#78855a]/10 blur-2xl" />
            <div className="relative overflow-hidden rounded-[2.4rem] border border-white/80 bg-[#eef0e5]/90 p-4 shadow-[0_35px_100px_rgba(54,61,39,.16)] backdrop-blur-xl sm:p-5">
              <div className="rounded-[1.9rem] bg-[#252b1d] p-5 text-white sm:p-7">
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-bold uppercase tracking-[.22em] text-[#b9c29e]">Sound channel</span>
                  <span className="rounded-full bg-[#667149]/30 px-2.5 py-1 text-[9px] font-bold uppercase tracking-widest text-[#d5ddba]">Live</span>
                </div>
                <div className="my-10 flex h-32 items-center justify-center gap-1.5">
                  {[18,34,55,82,112,68,40,92,125,76,48,88,116,62,30,52,94,70,38].map((h, i) => (
                    <motion.span key={i} animate={{ scaleY: [0.55, 1, .65] }} transition={{ duration: 1.1 + i*.03, repeat: Infinity, delay: i*.035 }}
                      className="w-1.5 rounded-full bg-[#aeb88b]" style={{ height: `${h}px` }} />
                  ))}
                </div>
                <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                  <div className="text-[9px] font-bold uppercase tracking-[.2em] text-white/40">Transmission</div>
                  <div className="mt-2 text-lg font-semibold tracking-tight">Whisper. Transfer. Done.</div>
                </div>
              </div>
              <div className="flex items-center justify-between px-2 pb-1 pt-4 text-[10px] font-bold uppercase tracking-[.18em] text-[#818875]">
                <span>Speaker → microphone</span>
                <span>SM1</span>
              </div>
            </div>
          </motion.div>
        </section>

        <section className="mt-16 border-t border-[#657047]/10 pt-8 sm:mt-24">
          <div className="flex flex-col items-start justify-between gap-5 sm:flex-row sm:items-center">
            <div>
              <div className="flex items-center gap-2 text-[10px] font-extrabold uppercase tracking-[.22em] text-[#7b826f]"><History size={14} /> Recent transmissions</div>
              <p className="mt-1 text-sm text-[#8a8f82]">Your latest local activity.</p>
            </div>
            {(() => {
              const historyStr = localStorage.getItem('soundmesh_history');
              if (!historyStr) return null;
              try {
                const history = JSON.parse(historyStr);
                return history.length > 3 ? (
                  <button onClick={onViewHistory} className="text-xs font-extrabold uppercase tracking-[.16em] text-[#667149] underline decoration-[#667149]/30 underline-offset-4 hover:text-[#4e5837]">View all history</button>
                ) : null;
              } catch { return null; }
            })()}
          </div>

          {(() => {
            const historyStr = localStorage.getItem('soundmesh_history');
            if (!historyStr) return <div className="mt-5 rounded-3xl border border-dashed border-[#657047]/15 bg-white/40 p-8 text-center text-sm text-[#999d92]">No transmissions yet.</div>;
            try {
              const history = JSON.parse(historyStr);
              if (history.length === 0) return <div className="mt-5 rounded-3xl border border-dashed border-[#657047]/15 bg-white/40 p-8 text-center text-sm text-[#999d92]">No transmissions yet.</div>;
              return (
                <div className="mt-5 grid gap-3 md:grid-cols-3">
                  {history.slice().reverse().slice(0, 3).map((item: any, i: number) => (
                    <motion.div key={i} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * .06 }}
                      className="group rounded-3xl border border-[#657047]/10 bg-white/70 p-4 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
                      <div className="flex items-center justify-between">
                        <div className={`grid h-9 w-9 place-items-center rounded-xl ${item.type === 'sent' ? 'bg-[#e5e9d8] text-[#667149]' : 'bg-[#ecefe5] text-[#7b8463]'}`}>
                          {item.type === 'sent' ? <Volume2 size={16} /> : <Mic size={16} />}
                        </div>
                        <span className="text-[9px] font-bold uppercase tracking-widest text-[#9a9d93]">{new Date(item.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                      </div>
                      <div className="mt-4 text-[9px] font-extrabold uppercase tracking-[.18em] text-[#858b79]">{item.type === 'sent' ? 'Sent' : 'Received'}</div>
                      <div className="mt-1 truncate text-sm font-semibold text-[#303625]">{item.message}</div>
                    </motion.div>
                  ))}
                </div>
              );
            } catch { return null; }
          })()}
        </section>
      </main>
    </div>
  );
}
