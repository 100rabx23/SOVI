import ggwaveFactory from 'ggwave';

export type GGWaveInstance = {
  getDefaultParameters: () => Record<string, any>;
  init: (params: Record<string, any>) => number;
  encode: (
    inst: number,
    message: string,
    protocolId: number,
    volume: number
  ) => Uint8Array;
  decode: (inst: number, samples: Uint8Array) => unknown;

  ProtocolId?: Record<string, number>;
  TxProtocolId?: Record<string, number>;
  SampleFormat?: Record<string, number>;
};

export type InitializedGGWave = {
  instance: GGWaveInstance;
  inst: number;
};

let instancePromise: Promise<InitializedGGWave> | null = null;

export function initGGWave(): Promise<InitializedGGWave> {
  if (instancePromise) return instancePromise;

  instancePromise = (async () => {
    try {
      const instance = (await ggwaveFactory()) as unknown as GGWaveInstance;
      console.log('[SOVI] ggwave exports:', Object.keys(instance));
      console.log('[SOVI] ProtocolId type:', typeof instance.ProtocolId);
      if (instance.ProtocolId) {
        const pid = instance.ProtocolId as unknown as Record<string, unknown>;
        const keys = Object.getOwnPropertyNames(pid);
        console.log('[SOVI] ProtocolId keys:', keys);
        for (const k of keys) {
          const v = pid[k];
          console.log(`  [SOVI] ProtocolId.${k} =`, v, typeof v === 'object' && v !== null ? (v as any).value : '');
        }
      }
      console.log('[SOVI] TxProtocolId:', instance.TxProtocolId);
      console.log('[SOVI] SampleFormat:', instance.SampleFormat);
      if (
        !instance ||
        typeof instance.getDefaultParameters !== 'function' ||
        typeof instance.init !== 'function' ||
        typeof instance.encode !== 'function' ||
        typeof instance.decode !== 'function'
      ) {
        throw new Error('Invalid ggwave API: required methods are missing.');
      }

      const params = instance.getDefaultParameters();

      if (!params || typeof params !== 'object') {
        throw new Error('ggwave returned invalid default parameters.');
      }

      // Preserve the package defaults for sample formats.
      // Set the rates expected by the SOVI audio pipeline.
      params.sampleRateInp = 48000;
      params.sampleRateOut = 48000;

      const inst = instance.init(params);

      // Instance ID 0 is valid.
      if (
        typeof inst !== 'number' ||
        !Number.isInteger(inst) ||
        inst < 0
      ) {
        throw new Error(
          `ggwave initialization failed: ${String(inst)}`
        );
      }

      return { instance, inst };
    } catch (error) {
      instancePromise = null;
      throw error instanceof Error
        ? error
        : new Error(String(error));
    }
  })();

  return instancePromise;
}

export function resetGGWaveInitialization(): void {
  instancePromise = null;
}