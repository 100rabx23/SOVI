
import { initGGWave } from './ggwaveManager';
import { float32ToWav } from './wavExport';

type GGWaveApi = {
  ProtocolId?: Record<string, number>;
  TxProtocolId?: Record<string, number>;
  encode: (
    instanceId: number,
    message: string,
    protocolId: number,
    volume: number
  ) => Uint8Array;
};

/**
 * Resolve the numeric protocol ID for AUDIBLE_FAST from the ggwave instance.
 *
 * Emscripten enum values are stored as objects with a `.value` property:
 *   instance.ProtocolId.GGWAVE_PROTOCOL_AUDIBLE_FAST  → { value: 1 }
 * Some builds expose plain numbers instead. Both forms are handled here.
 */
function getAudibleFastProtocol(instance: GGWaveApi): number {
  // Sources to search, in priority order.
  const enumSources: Array<Record<string, unknown> | undefined> = [
    instance.TxProtocolId as unknown as Record<string, unknown>,
    instance.ProtocolId as unknown as Record<string, unknown>,
  ];

  // Keys to try, in priority order.
  const targetKeys = [
    'GGWAVE_TX_PROTOCOL_AUDIBLE_FAST',
    'GGWAVE_PROTOCOL_AUDIBLE_FAST',
  ];

  /**
   * Extract a number from an enum entry.
   * Handles both plain numbers and Emscripten's { value: number } objects.
   */
  function resolveValue(raw: unknown): number | undefined {
    if (typeof raw === 'number') return raw;
    if (raw !== null && typeof raw === 'object') {
      const v = (raw as Record<string, unknown>).value;
      if (typeof v === 'number') return v;
    }
    return undefined;
  }

  for (const source of enumSources) {
    if (!source) continue;

    // 1. Check known key names directly on the object.
    for (const key of targetKeys) {
      const resolved = resolveValue(source[key]);
      if (resolved !== undefined) return resolved;
    }

    // 2. Check the prototype (Emscripten sometimes puts values there).
    const proto = Object.getPrototypeOf(source) as Record<string, unknown> | null;
    if (proto) {
      for (const key of targetKeys) {
        const resolved = resolveValue(proto[key]);
        if (resolved !== undefined) return resolved;
      }
    }

    // 3. Fallback: scan all own keys for anything containing "AUDIBLE_FAST".
    for (const key of Object.getOwnPropertyNames(source)) {
      if (!key.includes('AUDIBLE_FAST')) continue;
      const resolved = resolveValue(source[key]);
      if (resolved !== undefined) return resolved;
    }
  }

  // Log what we actually received to help with future debugging.
  console.error(
    '[SOVI] Could not find AUDIBLE_FAST protocol. Available ProtocolId keys:',
    instance.ProtocolId ? Object.getOwnPropertyNames(instance.ProtocolId) : 'undefined',
  );

  throw new Error(
    'GGWave audible-fast protocol was not found. ' +
    'Check the installed ggwave package API.'
  );
}

export async function encodeMessage(
  message: string
): Promise<Float32Array> {
  if (!message.trim()) {
    throw new Error('Message cannot be empty.');
  }

  const { instance, inst } = await initGGWave();
  const api = instance as unknown as GGWaveApi;

  const protocolId = getAudibleFastProtocol(api);
  // ggwave WASM encode() returns an Int8Array view into WASM heap memory,
  // NOT a Uint8Array — so `instanceof Uint8Array` always fails even when
  // the data is valid. Accept any ArrayBufferView instead.
  const encoded = api.encode(inst, message, protocolId, 50) as unknown as ArrayBufferView | null;

  if (!encoded || !encoded.byteLength) {
    throw new Error(
      `GGWave returned an empty or invalid waveform (type=${Object.prototype.toString.call(encoded)}).`
    );
  }

  if (encoded.byteLength % Float32Array.BYTES_PER_ELEMENT !== 0) {
    throw new Error(
      `GGWave waveform has an invalid byte length: ${encoded.byteLength}`
    );
  }

  // Copy bytes out of the WASM heap into a fresh owned ArrayBuffer.
  // The WASM heap view may be overwritten or neutered after encode() returns.
  const ownedBytes = new Uint8Array(encoded.byteLength);
  ownedBytes.set(new Uint8Array(encoded.buffer, encoded.byteOffset, encoded.byteLength));

  const view = new DataView(ownedBytes.buffer);
  const samples = new Float32Array(encoded.byteLength / Float32Array.BYTES_PER_ELEMENT);

  for (let i = 0; i < samples.length; i++) {
    samples[i] = view.getFloat32(i * 4, true);
  }

  console.log(
    `[SOVI] Encoded ${samples.length} samples` +
    ` (${(samples.length / 48000).toFixed(2)}s @ 48 kHz)`
  );

  return samples;
}

export async function transmitMessage(
  message: string,
  audioContext?: AudioContext
): Promise<void> {
  const samples = await encodeMessage(message);

  const context =
    audioContext ?? new AudioContext({ sampleRate: 48000 });

  if (context.state === 'suspended') {
    await context.resume();
  }

  const audioBuffer = context.createBuffer(
    1,
    samples.length,
    context.sampleRate
  );

  const safeSamples = new Float32Array(samples.length);
  safeSamples.set(samples);
  audioBuffer.copyToChannel(safeSamples, 0);

  const source = context.createBufferSource();
  source.buffer = audioBuffer;
  source.connect(context.destination);
  source.start();

  await new Promise<void>((resolve) => {
    source.onended = () => resolve();
  });

  source.disconnect();

  if (!audioContext) {
    await context.close();
  }
}

export async function exportMessageAsWav(
  message: string
): Promise<Blob> {
  const samples = await encodeMessage(message);
  return float32ToWav(samples, 48000);
}
