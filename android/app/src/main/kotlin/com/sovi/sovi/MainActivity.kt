package com.sovi.sovi

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.log10
import kotlin.math.sqrt

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.sovi.app/audio"
    private val EVENT_CHANNEL = "com.sovi.app/audio_stream"

    private var audioTrack: AudioTrack? = null
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var recordThread: Thread? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startPlayback" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val sampleRate = call.argument<Int>("sampleRate") ?: 44100
                    if (bytes != null) {
                        val success = playPcmBytes(bytes, sampleRate)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "PCM bytes cannot be null", null)
                    }
                }
                "stopPlayback" -> {
                    stopPcmPlayback()
                    result.success(true)
                }
                "startRecording" -> {
                    val sampleRate = call.argument<Int>("sampleRate") ?: 44100
                    val success = startPcmRecording(sampleRate)
                    result.success(success)
                }
                "stopRecording" -> {
                    stopPcmRecording()
                    result.success(true)
                }
                "getAudioHardwareStatus" -> {
                    val status = getHardwareStatus()
                    result.success(status)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun playPcmBytes(bytes: ByteArray, sampleRate: Int): Boolean {
        try {
            stopPcmPlayback()

            val bufferSize = AudioTrack.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )

            audioTrack = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(bufferSize.coerceAtLeast(bytes.size))
                .setTransferMode(AudioTrack.MODE_STATIC)
                .build()

            audioTrack?.write(bytes, 0, bytes.size)
            audioTrack?.play()
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun stopPcmPlayback() {
        try {
            audioTrack?.let {
                if (it.playState == AudioTrack.PLAYSTATE_PLAYING) {
                    it.stop()
                }
                it.release()
            }
            audioTrack = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun startPcmRecording(sampleRate: Int): Boolean {
        try {
            stopPcmRecording()

            val minBufferSize = AudioRecord.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )

            if (minBufferSize == AudioRecord.ERROR || minBufferSize == AudioRecord.ERROR_BAD_VALUE) {
                return false
            }

            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                minBufferSize * 2
            )

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                return false
            }

            audioRecord?.startRecording()
            isRecording = true

            recordThread = thread(start = true) {
                val buffer = ByteArray(minBufferSize)
                while (isRecording && audioRecord != null) {
                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (read > 0) {
                        val pcmChunk = buffer.copyOf(read)
                        val rmsDb = calculateRmsDb(pcmChunk, read)

                        mainHandler.post {
                            eventSink?.let { sink ->
                                val dataMap = mapOf(
                                    "pcm" to pcmChunk,
                                    "rmsDb" to rmsDb
                                )
                                sink.success(dataMap)
                            }
                        }
                    }
                }
            }

            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun stopPcmRecording() {
        isRecording = false
        try {
            audioRecord?.let {
                if (it.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                    it.stop()
                }
                it.release()
            }
            audioRecord = null
            recordThread?.interrupt()
            recordThread = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun calculateRmsDb(buffer: ByteArray, length: Int): Double {
        var sum = 0.0
        val numSamples = length / 2
        for (i in 0 until numSamples) {
            val sample = (buffer[i * 2 + 1].toInt() shl 8) or (buffer[i * 2].toInt() and 0xFF)
            sum += (sample * sample).toDouble()
        }
        val rms = sqrt(sum / numSamples)
        if (rms <= 0) return -100.0
        return 20 * log10(rms / 32768.0)
    }

    private fun getHardwareStatus(): Map<String, Any> {
        val sampleRate = 44100
        val minRxBuffer = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        val minTxBuffer = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )

        return mapOf(
            "sampleRate" to sampleRate,
            "rxMinBufferSize" to minRxBuffer,
            "txMinBufferSize" to minTxBuffer,
            "micAvailable" to (minRxBuffer > 0),
            "speakerAvailable" to (minTxBuffer > 0)
        )
    }

    override fun onDestroy() {
        stopPcmPlayback()
        stopPcmRecording()
        super.onDestroy()
    }
}
