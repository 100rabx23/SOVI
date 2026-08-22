import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class NativeAudioService {
  static const MethodChannel _methodChannel = MethodChannel('com.sovi.app/audio');
  static const EventChannel _eventChannel = EventChannel('com.sovi.app/audio_stream');

  static final NativeAudioService _instance = NativeAudioService._internal();
  factory NativeAudioService() => _instance;
  NativeAudioService._internal() {
    _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is Map) {
        final pcmBytes = event['pcm'] as Uint8List?;
        final rmsDb = (event['rmsDb'] as num?)?.toDouble();

        if (pcmBytes != null) {
          _pcmController.add(pcmBytes);
        }
        if (rmsDb != null) {
          _rmsController.add(rmsDb);
        }
      }
    });
  }

  final StreamController<Uint8List> _pcmController = StreamController<Uint8List>.broadcast();
  final StreamController<double> _rmsController = StreamController<double>.broadcast();

  Stream<Uint8List> get pcmStream => _pcmController.stream;
  Stream<double> get rmsStream => _rmsController.stream;

  /// Request Android microphone permission
  static Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start playing PCM audio bytes through Android AudioTrack speaker output
  Future<bool> startPlayback(Uint8List pcmBytes, {int sampleRate = 44100}) async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('startPlayback', {
        'bytes': pcmBytes,
        'sampleRate': sampleRate,
      });
      return res ?? false;
    } on PlatformException catch (e) {
      print("AudioTrack playback error: ${e.message}");
      return false;
    }
  }

  /// Stop AudioTrack playback
  Future<bool> stopPlayback() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('stopPlayback');
      return res ?? false;
    } on PlatformException catch (e) {
      print("AudioTrack stop error: ${e.message}");
      return false;
    }
  }

  /// Start AudioRecord microphone stream
  Future<bool> startRecording({int sampleRate = 44100}) async {
    final hasPerm = await requestMicPermission();
    if (!hasPerm) return false;

    try {
      final res = await _methodChannel.invokeMethod<bool>('startRecording', {
        'sampleRate': sampleRate,
      });
      return res ?? false;
    } on PlatformException catch (e) {
      print("AudioRecord start error: ${e.message}");
      return false;
    }
  }

  /// Stop AudioRecord microphone stream
  Future<bool> stopRecording() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('stopRecording');
      return res ?? false;
    } on PlatformException catch (e) {
      print("AudioRecord stop error: ${e.message}");
      return false;
    }
  }

  /// Get hardware audio capabilities
  Future<Map<String, dynamic>> getHardwareStatus() async {
    try {
      final res = await _methodChannel.invokeMapMethod<String, dynamic>('getHardwareStatus');
      return res ?? {};
    } on PlatformException catch (e) {
      print("Hardware status error: ${e.message}");
      return {};
    }
  }
}
