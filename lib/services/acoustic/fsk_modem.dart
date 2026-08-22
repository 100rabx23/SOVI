import 'dart:math';
import 'dart:typed_data';
import '../protocol/sovi_protocol.dart';

class ModemTestResult {
  final int transmittedBits;
  final int receivedBits;
  final int incorrectBits;
  final double ber;
  final bool isSuccess;

  ModemTestResult({
    required this.transmittedBits,
    required this.receivedBits,
    required this.incorrectBits,
    required this.ber,
    required this.isSuccess,
  });
}

class FskModem {
  static const double sampleRate = 44100.0;
  static const double freq0 = 18500.0; // Bit 0 (Mark)
  static const double freq1 = 19500.0; // Bit 1 (Space)
  static const double syncFreq = 18500.0;
  static const double amplitude = 0.45;
  static const double symbolTime = 0.010; // 10ms
  static const double syncTime = 0.50; // 500ms

  /// Generate deterministic Stage 1 test bit pattern (32, 128, 512, 1000 bits)
  static List<int> generateTestSequence(int numBits) {
    return List<int>.generate(numBits, (index) => (index % 2 == 0) ? 1 : 0);
  }

  /// Generate 2-FSK PCM Audio Float32 Buffer from a bitstream
  static Float32List synthesizeFskAudio(List<int> bits) {
    final samplesPerSymbol = (sampleRate * symbolTime).round();
    final syncSamplesCount = (sampleRate * syncTime).round();
    final leadingSilenceCount = (sampleRate * 0.20).round();
    final trailingSilenceCount = (sampleRate * 0.20).round();

    final allBits = [...SoviPacket.preambleBits, ...bits];
    final totalSamples = leadingSilenceCount +
        syncSamplesCount +
        (allBits.length * samplesPerSymbol) +
        trailingSilenceCount;

    final output = Float32List(totalSamples);
    var index = leadingSilenceCount;

    // 1. Synthesize Sync Tone (18.5 kHz for 500ms)
    for (var i = 0; i < syncSamplesCount; i++) {
      final t = i / sampleRate;
      output[index++] = (amplitude * sin(2 * pi * syncFreq * t)).toDouble();
    }

    // 2. Synthesize Symbol Tones (18.5 kHz / 19.5 kHz)
    for (var bit in allBits) {
      final targetFreq = (bit == 1) ? freq1 : freq0;
      for (var i = 0; i < samplesPerSymbol; i++) {
        final t = i / sampleRate;
        // Hann window envelope to prevent clicks
        final envelope = 0.5 * (1 - cos(2 * pi * i / samplesPerSymbol));
        output[index++] = (amplitude * sin(2 * pi * targetFreq * t) * envelope).toDouble();
      }
    }

    return output;
  }

  /// Goertzel algorithm frequency magnitude calculation at target frequency
  static double computeFrequencyEnergy(Float32List block, double targetFreq) {
    if (block.isEmpty) return 0.0;
    final n = block.length;
    final k = (0.5 + (n * targetFreq / sampleRate)).floor();
    final w = (2 * pi / n) * k;
    final cosine = cos(w);
    final coeff = 2 * cosine;
    var q0 = 0.0;
    var q1 = 0.0;
    var q2 = 0.0;

    for (var i = 0; i < n; i++) {
      final sample = block[i];
      q0 = coeff * q1 - q2 + sample;
      q2 = q1;
      q1 = q0;
    }

    final real = q1 - q2 * cosine;
    final imag = q2 * sin(w);
    return sqrt(real * real + imag * imag);
  }

  /// Detect symbol bit (0 or 1) for an audio block
  static int? detectSymbol(Float32List block) {
    final e0 = computeFrequencyEnergy(block, freq0);
    final e1 = computeFrequencyEnergy(block, freq1);
    final total = e0 + e1;

    if (total < 0.001) return null;
    return (e1 > e0) ? 1 : 0;
  }

  /// Search audio capture buffer for preamble and return decoded payload bits
  static List<int>? demodulateBuffer(Float32List audio) {
    final samplesPerSymbol = (sampleRate * symbolTime).round();
    final preambleSamples = SoviPacket.preambleBits.length * samplesPerSymbol;

    if (audio.length < preambleSamples) return null;

    // Scan for preamble position
    for (var start = 0; start <= audio.length - preambleSamples; start += samplesPerSymbol ~/ 4) {
      var matches = 0;
      for (var i = 0; i < SoviPacket.preambleBits.length; i++) {
        final blockStart = start + (i * samplesPerSymbol);
        final blockEnd = min(blockStart + samplesPerSymbol, audio.length);
        final block = Float32List.sublistView(audio, blockStart, blockEnd);

        final bit = detectSymbol(block);
        if (bit == SoviPacket.preambleBits[i]) {
          matches++;
        }
      }

      if (matches >= 14) {
        var bestStart = start;
        var maxMatches = matches;
        final searchMin = max(0, start - samplesPerSymbol);
        final searchMax = min(audio.length - preambleSamples, start + samplesPerSymbol);

        for (var s = searchMin; s <= searchMax; s += 2) {
          var m = 0;
          for (var i = 0; i < SoviPacket.preambleBits.length; i++) {
            final blockStart = s + (i * samplesPerSymbol);
            final blockEnd = min(blockStart + samplesPerSymbol, audio.length);
            final block = Float32List.sublistView(audio, blockStart, blockEnd);
            if (detectSymbol(block) == SoviPacket.preambleBits[i]) m++;
          }
          if (m > maxMatches) {
            maxMatches = m;
            bestStart = s;
          }
        }

        final payloadStart = bestStart + preambleSamples;
        final decodedBits = <int>[];

        for (var pos = payloadStart; pos + samplesPerSymbol <= audio.length; pos += samplesPerSymbol) {
          final block = Float32List.sublistView(audio, pos, pos + samplesPerSymbol);
          final bit = detectSymbol(block) ?? 0;
          decodedBits.add(bit);
        }

        return decodedBits;
      }
    }

    return null;
  }

  /// Demodulate PCM Float32 audio samples and attempt to decode a valid SoviPacket
  static SoviPacket? tryDecodeFromAudio(Float32List audio) {
    try {
      final bits = demodulateBuffer(audio);
      if (bits == null || bits.length < 128) return null;
      final bytes = SoviPacket.bitsToBytes(bits);
      return SoviPacket.decode(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Stage 1 Self-Test: Modulate, Demodulate, and calculate BER
  static ModemTestResult runModemSelfTest(List<int> knownBits) {
    final audio = synthesizeFskAudio(knownBits);
    final decodedBits = demodulateBuffer(audio);

    if (decodedBits == null) {
      return ModemTestResult(
        transmittedBits: knownBits.length,
        receivedBits: 0,
        incorrectBits: knownBits.length,
        ber: 1.0,
        isSuccess: false,
      );
    }

    var errors = 0;
    final compareLen = min(knownBits.length, decodedBits.length);
    for (var i = 0; i < compareLen; i++) {
      if (knownBits[i] != decodedBits[i]) {
        errors++;
      }
    }
    errors += (knownBits.length - compareLen).abs();

    final ber = errors / knownBits.length;
    return ModemTestResult(
      transmittedBits: knownBits.length,
      receivedBits: decodedBits.length,
      incorrectBits: errors,
      ber: ber,
      isSuccess: ber < 0.05,
    );
  }
}

/// Persistent Rolling PCM Receiver Buffer that accumulates incoming AudioRecord chunks
/// and decodes preambles that cross buffer boundaries.
class AcousticReceiverBuffer {
  final List<double> _buffer = [];
  static const int maxBufferSize = 44100 * 10; // 10 seconds of audio

  void appendSamples(Float32List newSamples) {
    _buffer.addAll(newSamples);
    if (_buffer.length > maxBufferSize) {
      _buffer.removeRange(0, _buffer.length - (44100 * 4));
    }
  }

  void clear() {
    _buffer.clear();
  }

  int get length => _buffer.length;

  /// Scan rolling buffer for preamble and return decoded SoviPacket when a valid packet passes CRC32
  SoviPacket? tryExtractPacket() {
    if (_buffer.length < 500) return null;

    final floatAudio = Float32List.fromList(_buffer);
    final samplesPerSymbol = (FskModem.sampleRate * FskModem.symbolTime).round();
    final preambleSamples = SoviPacket.preambleBits.length * samplesPerSymbol;

    if (floatAudio.length < preambleSamples) return null;

    for (var start = 0; start <= floatAudio.length - preambleSamples; start += samplesPerSymbol ~/ 4) {
      var matches = 0;
      for (var i = 0; i < SoviPacket.preambleBits.length; i++) {
        final blockStart = start + (i * samplesPerSymbol);
        final blockEnd = min(blockStart + samplesPerSymbol, floatAudio.length);
        final block = Float32List.sublistView(floatAudio, blockStart, blockEnd);

        final bit = FskModem.detectSymbol(block);
        if (bit == SoviPacket.preambleBits[i]) {
          matches++;
        }
      }

      if (matches >= 14) {
        var bestStart = start;
        var maxMatches = matches;
        final searchMin = max(0, start - samplesPerSymbol);
        final searchMax = min(floatAudio.length - preambleSamples, start + samplesPerSymbol);

        for (var s = searchMin; s <= searchMax; s += 2) {
          var m = 0;
          for (var i = 0; i < SoviPacket.preambleBits.length; i++) {
            final blockStart = s + (i * samplesPerSymbol);
            final blockEnd = min(blockStart + samplesPerSymbol, floatAudio.length);
            final block = Float32List.sublistView(floatAudio, blockStart, blockEnd);
            if (FskModem.detectSymbol(block) == SoviPacket.preambleBits[i]) m++;
          }
          if (m > maxMatches) {
            maxMatches = m;
            bestStart = s;
          }
        }

        final payloadStart = bestStart + preambleSamples;
        final decodedBits = <int>[];

        for (var pos = payloadStart; pos + samplesPerSymbol <= floatAudio.length; pos += samplesPerSymbol) {
          final block = Float32List.sublistView(floatAudio, pos, pos + samplesPerSymbol);
          final bit = FskModem.detectSymbol(block) ?? 0;
          decodedBits.add(bit);

          if (decodedBits.length >= 128 && decodedBits.length % 8 == 0) {
            try {
              final bytes = SoviPacket.bitsToBytes(decodedBits);
              final packet = SoviPacket.decode(bytes);
              final consumedIndex = payloadStart + (decodedBits.length * samplesPerSymbol);
              if (consumedIndex < _buffer.length) {
                _buffer.removeRange(0, consumedIndex);
              } else {
                _buffer.clear();
              }
              return packet;
            } catch (_) {}
          }
        }

        if (decodedBits.length >= 128) {
          final fullBitsCount = (decodedBits.length ~/ 8) * 8;
          try {
            final bytes = SoviPacket.bitsToBytes(decodedBits.sublist(0, fullBitsCount));
            final packet = SoviPacket.decode(bytes);
            final consumedIndex = payloadStart + (fullBitsCount * samplesPerSymbol);
            if (consumedIndex < _buffer.length) {
              _buffer.removeRange(0, consumedIndex);
            } else {
              _buffer.clear();
            }
            return packet;
          } catch (_) {}
        }
      }
    }

    return null;
  }
}

