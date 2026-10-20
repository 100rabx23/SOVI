import { initGGWave } from './ggwaveManager';

let audioContext: AudioContext | null = null;
let mediaStream: MediaStream | null = null;
let scriptNode: ScriptProcessorNode | null = null;
let sourceNode: MediaStreamAudioSourceNode | null = null;
let muteNode: GainNode | null = null;
let listening = false;
let startToken = 0;

function bytesToText(value: unknown): string | null {
  if (!value) return null;
  let bytes: Uint8Array;
  if (value instanceof Uint8Array) {
    bytes = value;
  } else if (value instanceof Int8Array) {
    bytes = new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
  } else if (value instanceof ArrayBuffer) {
    bytes = new Uint8Array(value);
  } else if (ArrayBuffer.isView(value)) {
    bytes = new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
  } else {
    return null;
  }
  if (!bytes.byteLength) return null;
  try {
    // Fatal UTF-8 rejects malformed byte sequences instead of displaying replacement/garbage characters.
    const text = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
    if (!text.trim()) return null;
    // Reject unexpected control characters while permitting ordinary whitespace.
    if (/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/.test(text)) return null;
    return text;
  } catch {
    return null;
  }
}

export async function startListening(
  onSignalDetected: () => void,
  onMessageDecoded: (message: string) => void,
  onAudioData: (data: Float32Array) => void,
  onError: (error: Error) => void,
): Promise<void> {
  // Avoid stacking multiple microphone pipelines.
  stopListening();
  const token = ++startToken;
  try {
    const { instance, inst } = await initGGWave();
    mediaStream = await navigator.mediaDevices.getUserMedia({
      audio: {
        channelCount: 1,
        echoCancellation: false,
        noiseSuppression: false,
        autoGainControl: false,
      },
    });
    if (token !== startToken) {
      mediaStream.getTracks().forEach((track) => track.stop());
      mediaStream = null;
      return;
    }

    audioContext = new AudioContext({ sampleRate: 48000 });
    if (audioContext.sampleRate !== 48000) {
      throw new Error(`SOVI requires 48000 Hz microphone capture; browser created ${audioContext.sampleRate} Hz context.`);
    }
    if (audioContext.state === 'suspended') await audioContext.resume();

    sourceNode = audioContext.createMediaStreamSource(mediaStream);
    scriptNode = audioContext.createScriptProcessor(4096, 1, 1);
    muteNode = audioContext.createGain();
    muteNode.gain.value = 0; // Keep the graph alive without feeding microphone audio to speakers.

    let lastSignalAt = 0;
    scriptNode.onaudioprocess = (event: AudioProcessingEvent) => {
      if (!listening || token !== startToken) return;
      const input = event.inputBuffer.getChannelData(0);
      const samples = new Float32Array(input); // Stable copy; never retain browser-owned buffers.
      onAudioData(samples);

      let sumSquares = 0;
      for (let i = 0; i < samples.length; i++) sumSquares += samples[i] * samples[i];
      const rms = Math.sqrt(sumSquares / Math.max(1, samples.length));
      const now = performance.now();
      if (rms > 0.008 && now - lastSignalAt > 250) {
        lastSignalAt = now;
        onSignalDetected();
      }

      // sampleFormatInp is F32, so pass the exact bytes of these F32 samples.
      // Decode each consecutive block; do not aggregate, reset, or discard earlier chunks.
      const sampleBytes = new Uint8Array(samples.buffer, samples.byteOffset, samples.byteLength);
      try {
        const result = instance.decode(inst, sampleBytes);
        const decoded = bytesToText(result);
        if (decoded !== null) onMessageDecoded(decoded);
      } catch (error) {
        // A failed block is not a decoded message. Keep listening for the next block.
        console.debug('ggwave decode block failed:', error);
      }
    };

    sourceNode.connect(scriptNode);
    scriptNode.connect(muteNode);
    muteNode.connect(audioContext.destination);
    listening = true;
  } catch (error) {
    stopListening();
    onError(error instanceof Error ? error : new Error(String(error)));
  }
}

export function stopListening(): void {
  listening = false;
  startToken++;
  if (scriptNode) {
    scriptNode.onaudioprocess = null;
    scriptNode.disconnect();
    scriptNode = null;
  }
  if (sourceNode) {
    sourceNode.disconnect();
    sourceNode = null;
  }
  if (muteNode) {
    muteNode.disconnect();
    muteNode = null;
  }
  if (mediaStream) {
    mediaStream.getTracks().forEach((track) => track.stop());
    mediaStream = null;
  }
  if (audioContext && audioContext.state !== 'closed') {
    void audioContext.close().catch(() => undefined);
  }
  audioContext = null;
}
