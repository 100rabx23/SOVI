import React, { useState, useEffect, useRef } from 'react';
import { ArrowLeft, Mic, MicOff, AlertCircle, CheckCircle2, Waves, RotateCcw, ShieldCheck } from 'lucide-react';
import { motion } from 'motion/react';
import { startListening, stopListening } from '../audio/ggwaveDecoder';
import { AudioWaveform } from '../components/AudioWaveform';

interface ReceivePageProps { onBack: () => void; }

export function ReceivePage({ onBack }: ReceivePageProps) {
  const [isListening, setIsListening] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [rawPayload, setRawPayload] = useState('');
  const [finalMessage, setFinalMessage] = useState('');
  const [status, setStatus] = useState<'idle' | 'listening' | 'decoding' | 'success' | 'error'>('idle');
  const [audioData, setAudioData] = useState<Float32Array | undefined>();
  const lastUpdateTime = useRef(0);

  useEffect(() => () => { stopListening(); }, []);

  const handleStartListening = async () => {
    setErrorMsg(''); setRawPayload(''); setFinalMessage(''); setStatus('listening'); setIsListening(true);
    await startListening(
      () => {},
      async (decodedString) => {
        setIsListening(false); stopListening();
        let payload = decodedString;
        if (decodedString.startsWith('SM1|')) {
          const parts = decodedString.split('|');
          if (parts.length >= 3) payload = parts.slice(2).join('|');
        }
        setRawPayload(payload);
        try {
          setFinalMessage(payload); setStatus('success');
          const history = JSON.parse(localStorage.getItem('soundmesh_history') || '[]');
          history.push({ type: 'received', message: payload, timestamp: new Date().toISOString() });
          localStorage.setItem('soundmesh_history', JSON.stringify(history));
        } catch (err: any) { console.error(err); setFinalMessage(payload); setStatus('success'); }
      },
      data => {
        const now = performance.now();
        if (now - lastUpdateTime.current > 33) { setAudioData(data); lastUpdateTime.current = now; }
      },
      err => { setIsListening(false); setStatus('error'); setErrorMsg(err.message || 'Microphone access denied or error occurred.'); }
    );
  };

  const handleStopListening = () => { stopListening(); setIsListening(false); setStatus('idle'); };
  const handleBack = () => { stopListening(); onBack(); };

  return (
    <div className="min-h-[100dvh] w-full overflow-hidden bg-[#f7f7f2] text-[#20251a]">
      <header className="sticky top-0 z-30 border-b border-[#657047]/10 bg-[#f7f7f2]/80 px-4 py-4 backdrop-blur-2xl sm:px-8">
        <div className="mx-auto flex max-w-5xl items-center justify-between">
          <button onClick={handleBack} className="grid h-10 w-10 place-items-center rounded-xl border border-[#657047]/15 bg-white/70 text-[#68734d] transition hover:-translate-x-0.5 hover:bg-white"><ArrowLeft size={19} /></button>
          <div className="text-center"><div className="text-[10px] font-extrabold uppercase tracking-[.25em] text-[#7b826f]">SoundMesh</div><div className="mt-0.5 text-sm font-black tracking-tight">Receive message</div></div>
          <div className="grid h-10 w-10 place-items-center rounded-xl bg-[#e8ebde] text-[#667149]"><Mic size={18} /></div>
        </div>
      </header>

      <main className="relative mx-auto flex min-h-[calc(100dvh-73px)] max-w-5xl items-center px-4 py-8 pb-28 sm:px-8">
        <div className="pointer-events-none absolute right-[-8rem] top-10 h-80 w-80 rounded-full bg-[#c4ccb0]/30 blur-3xl" />
        <div className="relative grid w-full gap-6 lg:grid-cols-[.8fr_1.2fr]">
          <section className="flex flex-col items-center justify-center rounded-[2rem] border border-[#657047]/10 bg-white/75 p-6 text-center shadow-[0_25px_80px_rgba(70,77,48,.08)] backdrop-blur-xl sm:p-9">
            <div className="flex items-center gap-2 text-[10px] font-extrabold uppercase tracking-[.22em] text-[#7c846f]"><ShieldCheck size={13} /> Private listening</div>
            {status !== 'success' ? (
              <>
                <div className="relative my-9">
                  {isListening && <><div className="absolute inset-0 scale-125 animate-ping rounded-full bg-[#8a965f]/10" /><div className="absolute -inset-6 animate-pulse rounded-full bg-[#aab58b]/15 blur-2xl" /></>}
                  <div className={`relative grid h-36 w-36 place-items-center rounded-[2.5rem] border transition-all duration-500 sm:h-44 sm:w-44 ${isListening ? 'border-[#87945e]/40 bg-[#68754a] text-white shadow-[0_25px_60px_rgba(104,117,74,.3)]' : 'border-[#657047]/10 bg-[#eef0e5] text-[#737c5d]'}`}>
                    <Mic size={52} />
                  </div>
                </div>
                <h1 className="text-2xl font-black tracking-[-.04em] sm:text-3xl">{status === 'listening' ? 'Listening...' : status === 'error' ? 'Something went wrong' : 'Ready to receive'}</h1>
                <p className="mt-3 max-w-xs text-sm leading-6 text-[#858a7c]">{status === 'listening' ? 'Keep the devices close and the sending device audible.' : 'Use your microphone to capture a nearby SoundMesh transmission.'}</p>
                {status === 'error' && <div className="mt-5 flex w-full items-start gap-3 rounded-2xl border border-red-200 bg-red-50 p-4 text-left text-xs leading-5 text-red-600"><AlertCircle size={17} className="shrink-0" />{errorMsg}</div>}
              </>
            ) : (
              <motion.div initial={{ opacity: 0, scale: .96 }} animate={{ opacity: 1, scale: 1 }} className="w-full">
                <div className="mx-auto my-8 grid h-16 w-16 place-items-center rounded-2xl bg-[#e6ead9] text-[#667149]"><CheckCircle2 size={31} /></div>
                <div className="text-[10px] font-extrabold uppercase tracking-[.2em] text-[#75805a]">Decoded successfully</div>
                <div className="mt-4 break-words text-2xl font-semibold leading-tight tracking-[-.03em] text-[#252b1d]">{finalMessage}</div>
              </motion.div>
            )}
          </section>

          <section className="rounded-[2rem] border border-[#657047]/10 bg-[#242a1d] p-5 text-white shadow-[0_25px_80px_rgba(36,42,29,.18)] sm:p-7">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-[10px] font-extrabold uppercase tracking-[.22em] text-[#b7c09b]"><Waves size={14} /> Incoming signal</div>
              <span className="rounded-full bg-white/5 px-3 py-1.5 text-[9px] font-bold uppercase tracking-widest text-white/40">{isListening ? 'Active' : 'Standby'}</span>
            </div>
            <div className="mt-7 rounded-[1.5rem] border border-white/10 bg-white/5 p-4 sm:p-6">
              <AudioWaveform isListening={isListening} audioData={audioData} />
            </div>
            {status === 'success' && (
              <div className="mt-5 rounded-2xl border border-white/10 bg-white/5 p-4">
                <div className="mb-2 text-[9px] font-bold uppercase tracking-[.2em] text-white/35">Raw payload</div>
                <div className="break-all font-mono text-[10px] leading-5 text-[#b9c39d]">{rawPayload}</div>
              </div>
            )}
            <p className="mt-5 text-xs leading-5 text-white/35">Acoustic data stays between the nearby devices. No network connection is required for the transfer.</p>
          </section>
        </div>
      </main>

      <div className="fixed bottom-0 left-0 right-0 z-40 border-t border-[#657047]/10 bg-[#f7f7f2]/85 p-4 backdrop-blur-2xl sm:p-5">
        <div className="mx-auto flex max-w-5xl gap-3">
          {status === 'success' && <button onClick={() => { setStatus('idle'); setFinalMessage(''); setRawPayload(''); }} className="grid w-14 place-items-center rounded-2xl border border-[#657047]/15 bg-white text-[#667149]"><RotateCcw size={18} /></button>}
          <button onClick={isListening ? handleStopListening : handleStartListening}
            className={`flex flex-1 items-center justify-center gap-3 rounded-2xl py-4 text-sm font-extrabold uppercase tracking-[.15em] transition active:scale-[.99] ${isListening ? 'border border-[#657047]/20 bg-white text-[#667149]' : 'bg-[#667149] text-white shadow-[0_14px_35px_rgba(102,113,73,.22)] hover:bg-[#59633e]'}`}>
            {isListening ? <><MicOff size={19} /> Stop listening</> : status === 'success' ? <><Mic size={19} /> Listen again</> : <><Mic size={19} /> Start listening</>}
          </button>
        </div>
      </div>
    </div>
  );
}
