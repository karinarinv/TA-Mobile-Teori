package com.example.tugasakhir_mobile

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.sin

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.rentbook.audio"
    @Volatile
    private var isBgmPlaying = false
    private var bgmThread: Thread? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playBgm" -> {
                    startBgm()
                    result.success(true)
                }
                "stopBgm" -> {
                    stopBgm()
                    result.success(true)
                }
                "playJumpscare" -> {
                    playJumpscare()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startBgm() {
        if (isBgmPlaying) return
        isBgmPlaying = true
        bgmThread = thread {
            try {
                val sampleRate = 22050
                val minBufferSize = AudioTrack.getMinBufferSize(
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AudioFormat.ENCODING_PCM_16BIT
                )
                val audioTrack = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_GAME)
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
                    .setBufferSizeInBytes(minBufferSize)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .build()

                audioTrack.play()

                // Melodi santai lorong perpustakaan (Mystery 8-bit chiptune loop)
                val notes = doubleArrayOf(
                    261.63, 329.63, 392.00, 523.25, 493.88, 392.00, 329.63, 293.66,
                    261.63, 311.13, 392.00, 466.16, 440.00, 349.23, 293.66, 246.94
                )
                var noteIdx = 0

                while (isBgmPlaying) {
                    val freq = notes[noteIdx % notes.size]
                    noteIdx++
                    val durationMs = 230
                    val numSamples = (sampleRate * (durationMs / 1000.0)).toInt()
                    val buffer = ShortArray(numSamples)

                    for (i in 0 until numSamples) {
                        val t = i.toDouble() / sampleRate
                        val envelope = if (i < 250) i / 250.0 else if (i > numSamples - 350) (numSamples - i) / 350.0 else 1.0
                        val raw = sin(2.0 * Math.PI * freq * t)
                        val sample = if (raw > 0) 5500.0 else -5500.0
                        buffer[i] = (sample * envelope).toInt().toShort()
                    }

                    audioTrack.write(buffer, 0, numSamples)
                }

                audioTrack.stop()
                audioTrack.release()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun stopBgm() {
        isBgmPlaying = false
        bgmThread = null
    }

    private fun playJumpscare() {
        stopBgm()
        thread {
            try {
                val sampleRate = 22050
                val minBufferSize = AudioTrack.getMinBufferSize(
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AudioFormat.ENCODING_PCM_16BIT
                )
                val audioTrack = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_GAME)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(minBufferSize)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .build()

                audioTrack.play()

                val durationMs = 850
                val numSamples = (sampleRate * (durationMs / 1000.0)).toInt()
                val buffer = ShortArray(numSamples)

                for (i in 0 until numSamples) {
                    val t = i.toDouble() / sampleRate
                    val freq1 = 1400.0 - (t * 900.0)
                    val freq2 = 1450.0 - (t * 850.0)
                    val noise = (Math.random() * 2.0 - 1.0) * 12000.0
                    val wave = (sin(2.0 * Math.PI * freq1 * t) + sin(2.0 * Math.PI * freq2 * t)) * 14000.0
                    buffer[i] = ((wave + noise) * 0.7).toInt().coerceIn(-32767, 32767).toShort()
                }

                audioTrack.write(buffer, 0, numSamples)
                audioTrack.stop()
                audioTrack.release()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        try {
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            if (vibrator != null && vibrator.hasVibrator()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator.vibrate(VibrationEffect.createOneShot(800, VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(800)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        stopBgm()
        super.onDestroy()
    }
}
