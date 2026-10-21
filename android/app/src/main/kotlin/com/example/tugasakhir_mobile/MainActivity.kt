package com.example.tugasakhir_mobile

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.MediaPlayer
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

    @Volatile
    private var isChasePlaying = false
    private var chaseThread: Thread? = null

    @Volatile
    private var isJumpscarePlaying = false
    private var jumpscareThread: Thread? = null
    @Volatile
    private var jumpscareVoicePlayer: MediaPlayer? = null

    private var vibrator: Vibrator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator

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
                "playChase" -> {
                    playChase()
                    result.success(true)
                }
                "stopChase" -> {
                    stopChase()
                    result.success(true)
                }
                "playJumpscare" -> {
                    playJumpscare()
                    result.success(true)
                }
                "stopJumpscare" -> {
                    stopJumpscare()
                    result.success(true)
                }
                "playTing" -> {
                    playTing()
                    result.success(true)
                }
                "playWin" -> {
                    playWin()
                    result.success(true)
                }
                "playLose" -> {
                    playLose()
                    result.success(true)
                }
                "stopAll" -> {
                    stopAll()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startBgm() {
        if (isBgmPlaying) return
        stopChase()
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

    // Suara Dikejar Springtrap Level 3: Menegangkan & Menyeramkan (Detak Jantung Cepat & Disonan Horor)
    private fun playChase() {
        if (isChasePlaying) return
        stopBgm()
        stopJumpscare()
        isChasePlaying = true

        chaseThread = thread {
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

                val notes = doubleArrayOf(55.0, 58.27, 55.0, 61.74, 55.0, 58.27, 440.0, 466.16)
                var step = 0
                val beatDurationMs = 120

                while (isChasePlaying) {
                    val freq = notes[step % notes.size]
                    step++
                    val numSamples = (sampleRate * (beatDurationMs / 1000.0)).toInt()
                    val buffer = ShortArray(numSamples)

                    for (i in 0 until numSamples) {
                        val t = i.toDouble() / sampleRate
                        val env = if (i < 120) i / 120.0 else Math.exp(-3.4 * (i.toDouble() / numSamples))
                        val wave = sin(2.0 * Math.PI * freq * t)
                        val distortion = if (wave > 0) 8500.0 else -8500.0
                        val subBass = sin(2.0 * Math.PI * 45.0 * t) * 6500.0
                        val sample = (distortion * 0.7 + subBass) * env
                        buffer[i] = sample.toInt().coerceIn(-32767, 32767).toShort()
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

    private fun stopChase() {
        isChasePlaying = false
        chaseThread = null
    }

    // Suara Ting Kristal saat Mengambil Buku Koleksi
    private fun playTing() {
        thread {
            try {
                val sampleRate = 22050
                val durationMs = 280
                val numSamples = (sampleRate * (durationMs / 1000.0)).toInt()
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

                val buffer = ShortArray(numSamples)
                val freq1 = 1760.0 // A6
                val freq2 = 2637.0 // E7
                for (i in 0 until numSamples) {
                    val t = i.toDouble() / sampleRate
                    val env = if (i < 50) i / 50.0 else Math.exp(-8.5 * (i.toDouble() / numSamples))
                    val wave = (sin(2.0 * Math.PI * freq1 * t) * 0.6 + sin(2.0 * Math.PI * freq2 * t) * 0.4)
                    buffer[i] = (wave * 19000.0 * env).toInt().coerceIn(-32767, 32767).toShort()
                }

                audioTrack.write(buffer, 0, numSamples)
                audioTrack.stop()
                audioTrack.release()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    // Suara Springtrap Jumpscare 2 Detik (Double: Screeching Animatronic Horror + Suara Custom)
    private fun playJumpscare() {
        stopBgm()
        stopChase()
        stopJumpscare()
        isJumpscarePlaying = true

        // Suara 1 (Audio custom pengguna didouble tanpa menghapus suara screamer asli)
        try {
            jumpscareVoicePlayer = MediaPlayer.create(this, R.raw.jumpscare_voice)?.apply {
                isLooping = false
                start()
                setOnCompletionListener { mp ->
                    try {
                        mp.release()
                    } catch (_: Exception) {}
                    if (jumpscareVoicePlayer == mp) {
                        jumpscareVoicePlayer = null
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Suara 2 (Screamer horor animatronik sintesis AudioTrack bersamaan / simultan)
        jumpscareThread = thread {
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

                val totalDurationMs = 2000 // Tepat 2 detik
                val totalSamples = (sampleRate * (totalDurationMs / 1000.0)).toInt()
                val chunkSize = 512
                val buffer = ShortArray(chunkSize)
                var sampleIndex = 0

                while (isJumpscarePlaying && sampleIndex < totalSamples) {
                    val count = minOf(chunkSize, totalSamples - sampleIndex)
                    for (i in 0 until count) {
                        val t = (sampleIndex + i).toDouble() / sampleRate

                        val freq1 = 1500.0 + (sin(2.0 * Math.PI * 35.0 * t) * 350.0)
                        val freq2 = 1850.0 + (sin(2.0 * Math.PI * 48.0 * t) * 450.0)
                        val bassFreq = 75.0 + (sin(2.0 * Math.PI * 12.0 * t) * 20.0)

                        val tremolo = 0.65 + 0.35 * sin(2.0 * Math.PI * 16.0 * t)

                        val wave1 = sin(2.0 * Math.PI * freq1 * t)
                        val wave2 = sin(2.0 * Math.PI * freq2 * t)
                        val bass = sin(2.0 * Math.PI * bassFreq * t)

                        val noise = (Math.random() * 2.0 - 1.0) * 11000.0
                        val combined = ((wave1 * 8000.0 + wave2 * 7000.0 + bass * 6000.0) * tremolo) + noise

                        val env = if (t < 0.08) t / 0.08 else if (t > 1.8) (2.0 - t) / 0.2 else 1.0
                        buffer[i] = (combined * env).toInt().coerceIn(-32767, 32767).toShort()
                    }
                    audioTrack.write(buffer, 0, count)
                    sampleIndex += count
                }

                audioTrack.stop()
                audioTrack.release()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        // Getar berdenyut intens 2 detik
        try {
            vibrator?.let { vib ->
                if (vib.hasVibrator()) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val timings = longArrayOf(0, 300, 80, 400, 80, 500, 80, 500)
                        val amplitudes = intArrayOf(0, 255, 0, 255, 0, 255, 0, 255)
                        vib.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
                    } else {
                        @Suppress("DEPRECATION")
                        vib.vibrate(1900)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopJumpscare() {
        isJumpscarePlaying = false
        jumpscareThread = null
        try {
            jumpscareVoicePlayer?.stop()
            jumpscareVoicePlayer?.release()
            jumpscareVoicePlayer = null
        } catch (_: Exception) {}
        try {
            vibrator?.cancel()
        } catch (e: Exception) {}
    }

    // Suara Menang Berhasil Next Level (Chiptune Victory Fanfare)
    private fun playWin() {
        stopBgm()
        stopChase()
        stopJumpscare()

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

                val notes = doubleArrayOf(523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98)
                val durations = intArrayOf(120, 120, 120, 260, 150, 480)

                for (idx in notes.indices) {
                    val freq = notes[idx]
                    val durationMs = durations[idx]
                    val numSamples = (sampleRate * (durationMs / 1000.0)).toInt()
                    val buffer = ShortArray(numSamples)

                    for (i in 0 until numSamples) {
                        val t = i.toDouble() / sampleRate
                        val envelope = if (i < 200) i / 200.0 else if (i > numSamples - 400) (numSamples - i) / 400.0 else 1.0

                        val raw1 = sin(2.0 * Math.PI * freq * t)
                        val raw2 = sin(4.0 * Math.PI * freq * t)
                        val square = if (raw1 > 0) 8000.0 else -8000.0
                        val sample = (square * 0.75 + raw2 * 2500.0) * envelope
                        buffer[i] = sample.toInt().coerceIn(-32767, 32767).toShort()
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

    // Suara Kalah / Game Over (Melancholic 8-bit Defeat Jingle)
    private fun playLose() {
        stopBgm()
        stopChase()
        stopJumpscare()

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

                val notes = doubleArrayOf(349.23, 329.63, 311.13, 293.66)
                val durations = intArrayOf(230, 230, 230, 600)

                for (idx in notes.indices) {
                    val baseFreq = notes[idx]
                    val durationMs = durations[idx]
                    val numSamples = (sampleRate * (durationMs / 1000.0)).toInt()
                    val buffer = ShortArray(numSamples)

                    for (i in 0 until numSamples) {
                        val t = i.toDouble() / sampleRate
                        val currentFreq = if (idx == 3) {
                            baseFreq - (t * 120.0)
                        } else {
                            baseFreq
                        }

                        val envelope = if (i < 250) i / 250.0 else if (i > numSamples - 500) (numSamples - i) / 500.0 else 1.0
                        val raw = sin(2.0 * Math.PI * currentFreq * t)
                        val square = if (raw > 0) 7000.0 else -7000.0
                        val sample = square * envelope * 0.8
                        buffer[i] = sample.toInt().coerceIn(-32767, 32767).toShort()
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

    private fun stopAll() {
        stopBgm()
        stopChase()
        stopJumpscare()
    }

    override fun onDestroy() {
        stopAll()
        super.onDestroy()
    }
}
