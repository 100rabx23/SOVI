import React, { useState, useEffect, useRef } from 'react';
import { ArrowLeft, Volume2, CheckCircle2, Play, Square, LockKeyhole, Waves, RotateCcw } from 'lucide-react';
import { motion } from 'motion/react';
import { transmitMessage, exportMessageAsWav } from '../audio/ggwaveEncoder';
import { AudioWaveform } from '../components/AudioWaveform';

interface SendPageProps { onBack: () => void; }

export function SendPage({ onBack }: SendPageProps) {
  const [message, setMessage] = useState('');
  const [status, setStatus] = useState<'idle' | 'ready' | 'transmitting' | 'success' | 'error'>('idle');
  const [compressedData, setCompressedData] = useState('');
  const [progress, setProgress] = useState(0);
  const [errorMsg, setErrorMsg] = useState('');
  const [isPlayingAudio, setIsPlayingAudio] = useState(false);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => () => { if (audioRef.current) audioRef.current.pause(); }, []);

  const handleTransmit = async () => {
    if (!message.trim()) return;
    try {
      setErrorMsg('');
      setStatus('transmitting');
      const payload = message.trim();
      setCompressedData(payload);
      const packet = `SM1|${Math.floor(Math.random() * 1000)}|${payload}`;
      await transmitMessage(packet);
      setStatus('success');
      const history = JSON.parse(localStorage.getItem('soundmesh_history') || '[]');
      history.push({ type: 'sent', message, timestamp: new Date().toISOString() });
      localStorage.setItem('soundmesh_history', JSON.stringify(history));
    } catch (err: any) {
      console.error(err);
      setStatus('error');
      setErrorMsg(err.message || 'An error occurred');
    }
  };

  const handlePlayAudio = async () => {
    if (isPlayingAudio && audioRef.current) {
      audioRef.current.pause(); audioRef.current = null; setIsPlayingAudio(false); return;
    }
    if (audioRef.current) audioRef.current.pause();
    try {
      setIsPlayingAudio(true);
      const packet = `SM1|${Math.floor(Math.random() * 1000)}|${message.trim()}`;
      const blob = await exportMessageAsWav(packet);
      const url = URL.createObjectURL(blob);
      const audio = new Audio(url);
      audioRef.current = audio;
      audio.onended = () => { setIsPlayingAudio(false); audioRef.current = null; URL.revokeObjectURL(url); };
      await audio.play();
    } catch (e) { console.error(e); setIsPlayingAudio(false); }
  };

  const reset = () => { setMessage(''); setStatus('idle'); setProgress(0); setCompressedData(''); setErrorMsg(''); };

  return (
    <div className="min-h-[100dvh] w-full overflow-hidden bg-[#f7f7f2] text-[#20251a]">
      <header className="sticky top-0 z-30 border-b border-[#657047]/10 bg-[#f7f7f2]/80 px-4 py-4 backdrop-blur-2xl sm:px-8">
        <div className="mx-auto flex max-w-5xl items-center justify-between">
          <button onClick={onBack} className="grid h-10 w-10 place-items-center rounded-xl border border-[#657047]/15 bg-white/70 text-[#68734d] transition hover:-translate-x-0.5 hover:bg-white"><ArrowLeft size={19} /></button>
          <div className="text-center">
            <div className="text-[10px] font-extrabold uppercase tracking-[.25em] text-[#7b826f]">SoundMesh</div>
            <div className="mt-0.5 text-sm font-black tracking-tight">Transmit message</div>
          </div>
          <div className="grid h-10 w-10 place-items-center rounded-xl bg-[#e8ebde] text-[#667149]"><Volume2 size={18} /></div>
        </div>
      </header>

      <main className="relative mx-auto flex min-h-[calc(100dvh-73px)] max-w-5xl items-center px-4 py-8 pb-28 sm:px-8">
        <div className="pointer-events-none absolute -left-32 top-10 h-72 w-72 rounded-full bg-[#c4ccb0]/25 blur-3xl" />
        <div className="relative grid w-full gap-6 lg:grid-cols-[1.2fr_.8fr]">
          <section className="rounded-[2rem] border border-[#657047]/10 bg-white/75 p-5 shadow-[0_25px_80px_rgba(70,77,48,.08)] backdrop-blur-xl sm:p-7">
            <div className="flex items-start justify-between gap-4">
              <div>
                <div className="flex items-center gap-2 text-[10px] font-extrabold uppercase tracking-[.22em] text-[#7c846f]"><LockKeyhole size={13} /> Local payload</div>
                <h1 className="mt-2 text-2xl font-black tracking-[-.04em] sm:text-3xl">What do you want to send?</h1>
              </div>
              <div className="hidden rounded-full bg-[#eef0e5] px-3 py-1.5 text-[9px] font-bold uppercase tracking-widest text-[#68734d] sm:block">SM1 protocol</div>
            </div>
            <textarea value={message} onChange={e => setMessage(e.target.value)}
              disabled={status !== 'idle' && status !== 'error'}
              placeholder="Write a short message..."
              className="mt-7 min-h-[260px] w-full resize-none rounded-[1.5rem] border border-[#657047]/15 bg-[#f8f8f3] p-5 text-lg leading-8 text-[#252a1d] outline-none transition placeholder:text-[#afb3a7] focus:border-[#71804e]/50 focus:bg-white focus:ring-4 focus:ring-[#71804e]/10 disabled:opacity-60 sm:min-h-[330px] sm:p-6 sm:text-xl"
            />
            <div className="mt-3 flex items-center justify-between text-[10px] font-bold uppercase tracking-widest text-[#9a9e91]">
              <span>{message.length} characters</span><span>Keep it concise</span>
            </div>
          </section>

          <section className="flex flex-col rounded-[2rem] border border-[#657047]/10 bg-[#242a1d] p-5 text-white shadow-[0_25px_80px_rgba(36,42,29,.18)] sm:p-7">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-[10px] font-extrabold uppercase tracking-[.22em] text-[#b7c09b]"><Waves size={14} /> Acoustic channel</div>
              <div className="h-2 w-2 rounded-full bg-[#aeb98c] shadow-[0_0_15px_#aeb98c]" />
            </div>
            <div className="flex flex-1 flex-col justify-center">
              {status === 'idle' || status === 'error' ? (
                <>
                  <div className="my-10">
                    <AudioWaveform isTransmitting={false} />
                  </div>
                  <p className="text-center text-sm leading-6 text-white/45">Your message will be encoded and played through the device speaker.</p>
                </>
              ) : (
                <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className="mt-8 space-y-5">
                  <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                    <div className="mb-2 text-[9px] font-bold uppercase tracking-[.2em] text-white/35">Payload</div>
                    <div className="break-all font-mono text-xs leading-5 text-[#d6dcc3]">{compressedData}</div>
                  </div>
                  <div className="rounded-2xl border border-white/10 bg-white/5 p-4"><AudioWaveform isTransmitting={status === 'transmitting'} /></div>
                  {status === 'transmitting' ? (
                    <div className="text-center"><div className="text-6xl font-black tracking-[-.06em] text-[#d9dfc8]">{progress}%</div><div className="mt-1 text-[9px] font-bold uppercase tracking-[.22em] text-white/35">Transmitting</div></div>
                  ) : (
                    <div className="text-center">
                      <div className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-[#657047]/30 text-[#d6dfbd]"><CheckCircle2 size={28} /></div>
                      <div className="mt-3 text-xs font-extrabold uppercase tracking-[.18em] text-[#d5ddbf]">Transmission complete</div>
                      <button onClick={handlePlayAudio} className="mx-auto mt-5 flex items-center gap-2 rounded-full border border-white/15 bg-white/5 px-4 py-2.5 text-[10px] font-bold uppercase tracking-widest text-white/70 transition hover:bg-white/10">
                        {isPlayingAudio ? <Square size={13} fill="currentColor" /> : <Play size={13} fill="currentColor" />} {isPlayingAudio ? 'Stop playback' : 'Play audio'}
                      </button>
                    </div>
                  )}
                </motion.div>
              )}
              {status === 'error' && <div className="mt-5 rounded-2xl border border-red-300/20 bg-red-400/10 p-4 text-center text-xs text-red-200">{errorMsg}</div>}
            </div>
          </section>
        </div>
      </main>

      <div className="fixed bottom-0 left-0 right-0 z-40 border-t border-[#657047]/10 bg-[#f7f7f2]/85 p-4 backdrop-blur-2xl sm:p-5">
        <div className="mx-auto flex max-w-5xl gap-3">
          {status === 'success' && <button onClick={reset} className="grid w-14 place-items-center rounded-2xl border border-[#657047]/15 bg-white text-[#667149]"><RotateCcw size={18} /></button>}
          <button onClick={status === 'success' ? reset : handleTransmit} disabled={!message.trim() || (status !== 'idle' && status !== 'error' && status !== 'success')}
            className="flex flex-1 items-center justify-center gap-3 rounded-2xl bg-[#667149] py-4 text-sm font-extrabold uppercase tracking-[.15em] text-white shadow-[0_14px_35px_rgba(102,113,73,.22)] transition hover:bg-[#59633e] active:scale-[.99] disabled:cursor-not-allowed disabled:opacity-40">
            {status === 'success' ? 'Send another' : status === 'transmitting' ? 'Transmitting...' : <><Volume2 size={19} /> Transmit via sound</>}
          </button>
        </div>
      </div>
    </div>
  );
}
