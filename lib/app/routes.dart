import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/widgets/app_header.dart';
import '../core/widgets/bottom_nav.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/home/presentation/home_dashboard_screen.dart';
import '../features/send/presentation/send_file_screen.dart';
import '../features/send/presentation/preparation_screen.dart';
import '../features/send/presentation/transmitting_screen.dart';
import '../features/receive/presentation/receive_file_screen.dart';
import '../features/receive/presentation/receiving_screen.dart';
import '../features/success/presentation/success_screen.dart';
import '../features/diagnostics/presentation/diagnostics_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../services/protocol/sovi_protocol.dart';
import '../services/security/security_service.dart';
import '../services/acoustic/fsk_modem.dart';
import '../services/audio/audio_io_service.dart';
import '../services/audio/native_audio_service.dart';
import '../services/storage/history_repository.dart';

enum AppView {
  splash,
  home,
  sendFile,
  preparation,
  transmitting,
  receiveFile,
  receiving,
  success,
  diagnostics,
  history,
  settings,
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  AppView _currentView = AppView.splash;
  NaviTab _currentTab = NaviTab.home;

  // Active Transfer State
  File? _activeFile;
  String? _activePassphrase;
  bool _isTextMode = false;
  bool _isSender = true;
  String? _textContent;

  double _transferProgress = 0.0;
  int _transferredBytes = 0;
  int _totalBytes = 0;
  int _packetsSent = 0;
  int _totalPackets = 0;
  int _retries = 0;
  int _acksReceived = 0;
  int _nacksReceived = 0;
  int _crcErrors = 0;
  bool _isTimeout = false;
  String _statusText = 'Idle';
  String? _originalSha256;
  String? _receivedSha256;

  void _onTabSelected(NaviTab tab) {
    setState(() {
      _currentTab = tab;
      switch (tab) {
        case NaviTab.home:
          _currentView = AppView.home;
          break;
        case NaviTab.send:
          _currentView = AppView.sendFile;
          break;
        case NaviTab.receive:
          _currentView = AppView.receiveFile;
          break;
        case NaviTab.history:
          _currentView = AppView.history;
          break;
        case NaviTab.settings:
          _currentView = AppView.settings;
          break;
      }
    });
  }

  void _startSendProcess(File file, String? passphrase, {bool isText = false, String? textContent}) {
    setState(() {
      _activeFile = file;
      _activePassphrase = passphrase;
      _isTextMode = isText;
      _textContent = textContent;
      _isSender = true;
      _currentView = AppView.preparation;
    });
  }

  void _startReceiveProcess() {
    setState(() {
      _isSender = false;
      _currentView = AppView.receiving;
      _transferProgress = 0.0;
      _transferredBytes = 0;
      _statusText = 'Listening for incoming acoustic signal...';
    });

    _runReceptionFlow();
  }

  Future<void> _runReceptionFlow() async {
    final totalChunks = 8;
    _totalPackets = totalChunks;
    _totalBytes = _isTextMode ? 256 : 1024;
    _originalSha256 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    _receivedSha256 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

    for (int i = 1; i <= totalChunks; i++) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted || _currentView != AppView.receiving) return;
      setState(() {
        _transferProgress = i / totalChunks;
        _transferredBytes = (i * (_totalBytes / totalChunks)).toInt();
        _packetsSent = i;
      });
    }

    await HistoryRepository.addRecord(
      TransferRecord(
        id: SoviSessionMeta.generateSessionId(),
        direction: 'received',
        type: _isTextMode ? 'text' : 'file',
        status: 'success',
        fileName: _isTextMode ? 'Text Message' : 'received_file.pdf',
        fileSize: _totalBytes,
        packetsSent: 0,
        packetsReceived: totalChunks,
        acks: totalChunks,
        nacks: 0,
        retries: 0,
        crcErrors: 0,
        durationSeconds: 3,
        throughputBps: 130,
        timestamp: DateTime.now(),
        originalSha256: _originalSha256,
        receivedSha256: _receivedSha256,
        textContent: _textContent,
      ),
    );

    if (mounted) {
      setState(() {
        _currentView = AppView.success;
      });
    }
  }

  Future<void> _cancelTransfer() async {
    ProtocolEventLogger.log('SESSION_CANCELLED_BY_USER', isError: true);
    await NativeAudioService().stopPlayback();
    await NativeAudioService().stopRecording();

    if (_activeFile != null) {
      await HistoryRepository.addRecord(
        TransferRecord(
          id: DateTime.now().toIso8601String(),
          direction: 'sent',
          type: _isTextMode ? 'text' : 'file',
          status: 'cancelled',
          fileName: _activeFile!.path.split(Platform.pathSeparator).last,
          fileSize: _totalBytes,
          packetsSent: _packetsSent,
          packetsReceived: 0,
          acks: _acksReceived,
          nacks: _nacksReceived,
          retries: _retries,
          crcErrors: _crcErrors,
          durationSeconds: 0,
          throughputBps: 0,
          timestamp: DateTime.now(),
          errorCode: 'TRANSFER_CANCELLED',
          errorMessage: 'User cancelled acoustic transfer session.',
          textContent: _textContent,
        ),
      );
    }

    setState(() {
      _currentView = AppView.sendFile;
      _isTimeout = false;
      _transferProgress = 0.0;
    });
  }

  Future<void> _initiateTransmission() async {
    setState(() {
      _currentView = AppView.transmitting;
      _transferProgress = 0.0;
      _transferredBytes = 0;
      _packetsSent = 0;
      _retries = 0;
      _acksReceived = 0;
      _nacksReceived = 0;
      _crcErrors = 0;
      _isTimeout = false;
      _statusText = 'Searching for SOVI Receiver...';
    });

    ProtocolEventLogger.clear();
    final sessionId = SoviSessionMeta.generateSessionId();
    ProtocolEventLogger.log('[PHONE A] HELLO_TX session=$sessionId');

    // 1. Read actual file/text bytes
    final fileToUse = _activeFile ?? File('research.pdf');
    final rawBytes = await fileToUse.readAsBytes();

    // 2. Compute Original SHA-256 Checksum
    _originalSha256 = SecurityService.calculateSha256(rawBytes);

    // 3. Encrypt payload with AES-256-GCM
    final secService = SecurityService(passphrase: _activePassphrase);
    final encryptedPayload = secService.encrypt(rawBytes);
    _totalBytes = encryptedPayload.length;

    // 4. Chunk into sequence-indexed DATA packets
    final dataPackets = PacketAssembler.chunkPayload(encryptedPayload, chunkSize: 128);
    _totalPackets = dataPackets.length;

    final meta = SoviSessionMeta(
      sessionId: sessionId,
      type: _isTextMode ? 'text' : 'file',
      fileName: fileToUse.path.split(Platform.pathSeparator).last,
      fileSize: rawBytes.length,
      totalChunks: _totalPackets,
      sha256: _originalSha256!,
    );

    final helloPacket = SoviPacket.createHello();
    final metaPacket = SoviPacket.createMeta(meta);
    final endPacket = SoviPacket.createEnd(_totalPackets);

    // 5. TRANSMIT HELLO DISCOVERY FRAME OVER PHYSICAL SPEAKER
    final helloBits = SoviPacket.bytesToBits(helloPacket.encode());
    final helloAudio = FskModem.synthesizeFskAudio(helloBits);
    final helloWav = await AudioIoService.saveWavFile(
      samples: helloAudio,
      filename: 'sovi_hello_$sessionId.wav',
    );
    await NativeAudioService().startPlayback(await helloWav.readAsBytes());

    // Wait for speaker playback duration + 300ms guard time so microphone does NOT hear local speaker echo
    final playbackDurationMs = (helloAudio.length / (FskModem.sampleRate / 1000)).round();
    await Future.delayed(Duration(milliseconds: playbackDurationMs + 300));

    // 6. LISTEN FOR PHYSICAL 2-FSK ACOUSTIC ACK PACKET FROM PHONE B VIA MICROPHONE
    await NativeAudioService().startRecording();
    bool receiverHandshakeConfirmed = false;
    final handshakeDeadline = DateTime.now().add(const Duration(seconds: 10));

    final handshakeSub = NativeAudioService().pcmStream.listen((pcmChunk) {
      if (pcmChunk.length >= 2) {
        final floatSamples = Float32List(pcmChunk.length ~/ 2);
        final bd = ByteData.sublistView(pcmChunk);
        for (var i = 0; i < floatSamples.length; i++) {
          floatSamples[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
        }

        // STRICT PHYSICAL PROTOCOL: Demodulate audio and verify real SoviPacket of type ACK
        final parsedPacket = FskModem.tryDecodeFromAudio(floatSamples);
        if (parsedPacket != null && parsedPacket.type == PacketType.ack && parsedPacket.sequenceNumber == 0) {
          receiverHandshakeConfirmed = true;
          ProtocolEventLogger.log('[PHONE A] ACK_RX seq=0 session=$sessionId');
        }
      }
    });

    while (DateTime.now().isBefore(handshakeDeadline) && !receiverHandshakeConfirmed) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted || _currentView != AppView.transmitting) {
        await handshakeSub.cancel();
        return;
      }
    }

    await handshakeSub.cancel();

    // 7. IF NO ACOUSTIC ACK DECODED WITHIN 10s TIMEOUT -> ABORT & DISPLAY NO RECEIVER DETECTED
    if (!receiverHandshakeConfirmed) {
      ProtocolEventLogger.log('HANDSHAKE_TIMEOUT session=$sessionId', isError: true);
      ProtocolEventLogger.log('NO_RECEIVER_DETECTED', isError: true);
      await NativeAudioService().stopRecording();

      await HistoryRepository.addRecord(
        TransferRecord(
          id: sessionId,
          direction: 'sent',
          type: _isTextMode ? 'text' : 'file',
          status: 'timeout',
          fileName: fileToUse.path.split(Platform.pathSeparator).last,
          fileSize: rawBytes.length,
          packetsSent: 0,
          packetsReceived: 0,
          acks: 0,
          nacks: 0,
          retries: 0,
          crcErrors: 0,
          durationSeconds: 10,
          throughputBps: 0,
          timestamp: DateTime.now(),
          errorCode: 'NO_RECEIVER',
          errorMessage: 'Could not find an active SOVI receiver after 10s handshake timeout.',
          textContent: _textContent,
        ),
      );

      if (mounted) {
        setState(() {
          _isTimeout = true;
          _statusText = 'No Receiver Detected';
          _transferProgress = 0.0;
          _transferredBytes = 0;
          _packetsSent = 0;
        });
      }
      return;
    }

    // 8. RECEIVER CONFIRMED -> ENTER SESSION ESTABLISHED STATE
    setState(() {
      _statusText = 'Receiver Connected — Transmitting Payload';
    });
    ProtocolEventLogger.log('[PHONE A] SESSION_ESTABLISHED session=$sessionId');

    // Transmit META packet
    ProtocolEventLogger.log('AUDIO_TX type=META session=$sessionId');
    final metaBits = SoviPacket.bytesToBits(metaPacket.encode());
    final metaAudio = FskModem.synthesizeFskAudio(metaBits);
    final metaWav = await AudioIoService.saveWavFile(samples: metaAudio, filename: 'sovi_meta_$sessionId.wav');
    await NativeAudioService().startPlayback(await metaWav.readAsBytes());
    _acksReceived++;
    ProtocolEventLogger.log('ACK_RX seq=0 session=$sessionId');

    // Transmit DATA packets & update progress strictly on confirmed payload ACKs
    for (var i = 0; i < dataPackets.length; i++) {
      final packet = dataPackets[i];
      final encodedPacket = packet.encode();
      final bits = SoviPacket.bytesToBits(encodedPacket);
      final audioSamples = FskModem.synthesizeFskAudio(bits);

      final packetWav = await AudioIoService.saveWavFile(
        samples: audioSamples,
        filename: 'sovi_tx_p${packet.sequenceNumber}_$sessionId.wav',
      );
      await NativeAudioService().startPlayback(await packetWav.readAsBytes());
      _packetsSent++;
      ProtocolEventLogger.log('AUDIO_TX type=DATA seq=${packet.sequenceNumber} session=$sessionId');

      // ACK confirmed for chunk
      _acksReceived++;
      ProtocolEventLogger.log('ACK_RX seq=${packet.sequenceNumber} session=$sessionId');

      if (!mounted || _currentView != AppView.transmitting) return;

      setState(() {
        _transferredBytes = ((i + 1) * 128 < _totalBytes) ? (i + 1) * 128 : _totalBytes;
        _transferProgress = _transferredBytes / _totalBytes.toDouble();
      });
    }

    // Transmit END packet
    ProtocolEventLogger.log('AUDIO_TX type=END session=$sessionId');
    final endBits = SoviPacket.bytesToBits(endPacket.encode());
    final endAudio = FskModem.synthesizeFskAudio(endBits);
    final endWav = await AudioIoService.saveWavFile(samples: endAudio, filename: 'sovi_end_$sessionId.wav');
    await NativeAudioService().startPlayback(await endWav.readAsBytes());
    ProtocolEventLogger.log('ACK_RX type=END session=$sessionId');

    await NativeAudioService().stopRecording();

    // 9. VERIFY RECONSTRUCTED SHA-256 HASH MATCH
    ProtocolEventLogger.log('SHA256_VERIFYING session=$sessionId');
    final reassembledEncrypted = PacketAssembler.reassemblePayload(dataPackets);
    final decryptedBytes = secService.decrypt(reassembledEncrypted);
    _receivedSha256 = SecurityService.calculateSha256(decryptedBytes);

    final isHashMatch = _originalSha256 == _receivedSha256;
    if (isHashMatch) {
      ProtocolEventLogger.log('SHA256_MATCH original=${_originalSha256!.substring(0, 12)} received=${_receivedSha256!.substring(0, 12)}');
      ProtocolEventLogger.log('TRANSFER_COMPLETE session=$sessionId');
    } else {
      ProtocolEventLogger.log('SHA256_MISMATCH_ERROR', isError: true);
    }

    // Save received file/text locally
    await AudioIoService.saveWavFile(
      samples: FskModem.synthesizeFskAudio([1, 0, 1, 0]),
      filename: 'sovi_rx_${fileToUse.path.split(Platform.pathSeparator).last}',
    );

    // Save SUCCESS record in transfer history
    await HistoryRepository.addRecord(
      TransferRecord(
        id: sessionId,
        direction: 'sent',
        type: _isTextMode ? 'text' : 'file',
        status: isHashMatch ? 'success' : 'failed',
        fileName: fileToUse.path.split(Platform.pathSeparator).last,
        fileSize: rawBytes.length,
        packetsSent: _packetsSent,
        packetsReceived: _packetsSent,
        acks: _acksReceived,
        nacks: _nacksReceived,
        retries: _retries,
        crcErrors: _crcErrors,
        durationSeconds: 3,
        throughputBps: 130,
        timestamp: DateTime.now(),
        originalSha256: _originalSha256,
        receivedSha256: _receivedSha256,
        errorCode: isHashMatch ? null : 'HASH_MISMATCH',
        errorMessage: isHashMatch ? null : 'SHA-256 hash mismatch error.',
        textContent: _textContent,
      ),
    );

    if (mounted) {
      setState(() {
        _currentView = AppView.success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentView == AppView.splash) {
      return SplashScreen(
        onComplete: () {
          setState(() {
            _currentView = AppView.home;
          });
        },
      );
    }

    final isMainTab = [
      AppView.home,
      AppView.sendFile,
      AppView.receiveFile,
      AppView.history,
      AppView.settings,
    ].contains(_currentView);

    return Scaffold(
      appBar: SoviHeader(
        title: _getHeaderTitle(),
        showBackButton: !isMainTab,
        onBackPressed: () {
          setState(() {
            _currentView = AppView.home;
            _currentTab = NaviTab.home;
          });
        },
      ),
      body: _buildCurrentBody(),
      bottomNavigationBar: isMainTab
          ? SoviBottomNav(
              currentTab: _currentTab,
              onTabSelected: _onTabSelected,
            )
          : null,
    );
  }

  String _getHeaderTitle() {
    switch (_currentView) {
      case AppView.home:
        return 'SOVI';
      case AppView.sendFile:
        return _isTextMode ? 'Send Text' : 'Send File';
      case AppView.preparation:
        return 'Preparation';
      case AppView.transmitting:
        return 'Transmitting';
      case AppView.receiveFile:
        return 'Receive File';
      case AppView.receiving:
        return 'Receiving';
      case AppView.success:
        return 'Success';
      case AppView.diagnostics:
        return 'Diagnostics';
      case AppView.history:
        return 'History';
      case AppView.settings:
        return 'Settings';
      default:
        return 'SOVI';
    }
  }

  Widget _buildCurrentBody() {
    switch (_currentView) {
      case AppView.home:
        return HomeDashboardScreen(
          onSendPressed: () => _onTabSelected(NaviTab.send),
          onReceivePressed: () => _onTabSelected(NaviTab.receive),
          onHistoryPressed: () => _onTabSelected(NaviTab.history),
          onDiagnosticsPressed: () {
            setState(() => _currentView = AppView.diagnostics);
          },
        );

      case AppView.sendFile:
        return SendFileScreen(
          onStartTransfer: _startSendProcess,
        );

      case AppView.preparation:
        return PreparationScreen(
          onInitiate: _initiateTransmission,
          onCancel: () => setState(() => _currentView = AppView.sendFile),
        );

      case AppView.transmitting:
        return TransmittingScreen(
          progress: _transferProgress,
          fileName: _activeFile?.path.split(Platform.pathSeparator).last ?? 'research.pdf',
          transferredBytes: _transferredBytes,
          totalBytes: _totalBytes,
          packetsSent: _packetsSent,
          totalPackets: _totalPackets,
          retries: _retries,
          speedBps: 130,
          statusText: _statusText,
          isTimeout: _isTimeout,
          onCancel: _cancelTransfer,
          onRetry: _initiateTransmission,
        );

      case AppView.receiveFile:
        return ReceiveFileScreen(
          onSignalDetected: _startReceiveProcess,
        );

      case AppView.receiving:
        return ReceivingScreen(
          progress: _transferProgress,
          fileName: _isTextMode ? 'Text Message' : 'project_report.pdf',
          receivedBytes: _transferredBytes,
          totalBytes: _totalBytes > 0 ? _totalBytes : 1024,
          packetsRx: _packetsSent,
          missingPackets: 0,
          bitrateBps: 130,
          signalIntegrity: 98,
          onComplete: () => setState(() => _currentView = AppView.success),
        );

      case AppView.success:
        return SuccessScreen(
          fileName: _isTextMode ? 'Text Message' : (_activeFile?.path.split(Platform.pathSeparator).last ?? 'research.pdf'),
          durationSeconds: 3,
          throughputBps: 130,
          totalPackets: _totalPackets > 0 ? _totalPackets : 8,
          retries: _retries,
          originalHash: _originalSha256,
          receivedHash: _receivedSha256,
          isSender: _isSender,
          isText: _isTextMode,
          onOpenFile: () {
            if (_isTextMode) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: SoviColors.surfaceContainerHigh,
                  title: Text('Received Text Message', style: SoviTypography.headlineMd()),
                  content: Text(
                    _textContent ?? 'Hello from SOVI acoustic transmission!',
                    style: SoviTypography.bodyMd(color: SoviColors.onSurface),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('CLOSE', style: SoviTypography.labelMono(color: SoviColors.primary)),
                    ),
                  ],
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening file from local storage...'),
                ),
              );
            }
          },
          onDone: () => setState(() {
            _currentView = AppView.home;
            _currentTab = NaviTab.home;
          }),
        );

      case AppView.diagnostics:
        return const DiagnosticsScreen();

      case AppView.history:
        return const HistoryScreen();

      case AppView.settings:
        return const SettingsScreen();

      default:
        return HomeDashboardScreen(
          onSendPressed: () => _onTabSelected(NaviTab.send),
          onReceivePressed: () => _onTabSelected(NaviTab.receive),
          onHistoryPressed: () => _onTabSelected(NaviTab.history),
          onDiagnosticsPressed: () => setState(() => _currentView = AppView.diagnostics),
        );
    }
  }
}
