import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AudioIoService {
  /// Save Float32 PCM audio samples to 16-bit PCM WAV file
  static Future<File> saveWavFile({
    required Float32List samples,
    required String filename,
    int sampleRate = 44100,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final soviDir = Directory(p.join(dir.path, 'sovi_audio'));
    if (!await soviDir.exists()) {
      await soviDir.create(recursive: true);
    }

    final file = File(p.join(soviDir.path, filename));
    final bytesBuilder = BytesBuilder();

    // 16-bit PCM conversion
    final numSamples = samples.length;
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;

    // RIFF Header
    bytesBuilder.add(Uint8List.fromList('RIFF'.codeUnits));
    final bdSize = ByteData(4)..setUint32(0, fileSize, Endian.little);
    bytesBuilder.add(bdSize.buffer.asUint8List());
    bytesBuilder.add(Uint8List.fromList('WAVE'.codeUnits));

    // fmt Subchunk
    bytesBuilder.add(Uint8List.fromList('fmt '.codeUnits));
    final bdFmtSize = ByteData(4)..setUint32(0, 16, Endian.little);
    bytesBuilder.add(bdFmtSize.buffer.asUint8List());
    final bdAudioFormat = ByteData(2)..setUint16(0, 1, Endian.little); // PCM
    bytesBuilder.add(bdAudioFormat.buffer.asUint8List());
    final bdNumChannels = ByteData(2)..setUint16(0, 1, Endian.little); // Mono
    bytesBuilder.add(bdNumChannels.buffer.asUint8List());
    final bdSampleRate = ByteData(4)..setUint32(0, sampleRate, Endian.little);
    bytesBuilder.add(bdSampleRate.buffer.asUint8List());
    final bdByteRate = ByteData(4)..setUint32(0, sampleRate * 2, Endian.little);
    bytesBuilder.add(bdByteRate.buffer.asUint8List());
    final bdBlockAlign = ByteData(2)..setUint16(0, 2, Endian.little);
    bytesBuilder.add(bdBlockAlign.buffer.asUint8List());
    final bdBitsPerSample = ByteData(2)..setUint16(0, 16, Endian.little);
    bytesBuilder.add(bdBitsPerSample.buffer.asUint8List());

    // data Subchunk
    bytesBuilder.add(Uint8List.fromList('data'.codeUnits));
    final bdDataSize = ByteData(4)..setUint32(0, dataSize, Endian.little);
    bytesBuilder.add(bdDataSize.buffer.asUint8List());

    // PCM 16-bit Sample Payload
    final pcmBytes = Uint8List(dataSize);
    final pcmByteData = ByteData.sublistView(pcmBytes);
    for (var i = 0; i < numSamples; i++) {
      final sample = samples[i].clamp(-1.0, 1.0);
      final intSample = (sample * 32767.0).round();
      pcmByteData.setInt16(i * 2, intSample, Endian.little);
    }
    bytesBuilder.add(pcmBytes);

    return await file.writeAsBytes(bytesBuilder.toBytes());
  }

  /// Read WAV file and parse float32 samples
  static Future<Float32List> readWavFile(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length < 44) {
      throw const FormatException("Invalid WAV file: header too short");
    }

    final dataSublist = bytes.sublist(44);
    final sampleCount = dataSublist.length ~/ 2;
    final samples = Float32List(sampleCount);
    final bd = ByteData.sublistView(dataSublist);

    for (var i = 0; i < sampleCount; i++) {
      final intSample = bd.getInt16(i * 2, Endian.little);
      samples[i] = intSample / 32768.0;
    }

    return samples;
  }
}
