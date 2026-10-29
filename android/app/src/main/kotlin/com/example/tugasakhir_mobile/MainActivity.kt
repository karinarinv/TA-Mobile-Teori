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
    // Harus sama dengan MethodChannel pada lib/services/game_audio_service.dart.
    private val CHANNEL = "com.rentbook.audio"

    @Volatile
    private var isBgmPlaying = false
    private var bgmTrack: AudioTrack? = null

    @Volatile
    private var isChasePlaying = false
    private var chaseTrack: AudioTrack? = null

    @Volatile
    private var isJumpscarePlaying = false
    private var jumpscareTrack: AudioTrack? = null
    @Volatile
    private var jumpscareVoicePlayer: MediaPlayer? = null

    @Volatile
    private var isWinPlaying = false
    private var winTrack: AudioTrack? = null

    private var vibrator: Vibrator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator

        // Terjemahkan perintah audio dari Flutter menjadi pemanggilan fungsi Android.
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
                "playPageTurn" -> {
                    playPageTurn()
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
        stopAll()
        isBgmPlaying = true
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

                bgmTrack = audioTrack
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
            } finally {
                if (bgmTrack != null) {
                    try { bgmTrack?.release() } catch (_: Exception) {}
                    bgmTrack = null
                }
            }
        }
    }

    private fun stopBgm() {
        isBgmPlaying = false
        try {
            bgmTrack?.stop()
            bgmTrack?.release()
        } catch (_: Exception) {}
        bgmTrack = null
    }

    // Suara Dikejar Wikwok Level 3: Menegangkan & Bersih (Detak Jantung Cepat)
    private fun playChase() {
        if (isChasePlaying) return
        stopAll()
        isChasePlaying = true

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

                chaseTrack = audioTrack
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
            } finally {
                if (chaseTrack != null) {
                    try { chaseTrack?.release() } catch (_: Exception) {}
                    chaseTrack = null
                }
            }
        }
    }

    private fun stopChase() {
        isChasePlaying = false
        try {
            chaseTrack?.stop()
            chaseTrack?.release()
        } catch (_: Exception) {}
        chaseTrack = null
    }

    // Suara Jumpscare Retro Synthesizer Arcade + Getaran Layar
    private fun playJumpscare() {
        stopAll()
        isJumpscarePlaying = true
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

                jumpscareTrack = audioTrack
                audioTrack.play()

                val durationMs = 850
                val numSamples = (sampleRate * (durationMs / 1000.0)).toInt()
                val buffer = ShortArray(numSamples)

                for (i in 0 until numSamples) {
                    if (!isJumpscarePlaying) break
                    val t = i.toDouble() / sampleRate
                    val freq1 = 1400.0 - (t * 900.0)
                    val freq2 = 1450.0 - (t * 850.0)
                    val noise = (Math.random() * 2.0 - 1.0) * 12000.0
                    val wave = (sin(2.0 * Math.PI * freq1 * t) + sin(2.0 * Math.PI * freq2 * t)) * 14000.0
                    buffer[i] = ((wave + noise) * 0.7).toInt().coerceIn(-32767, 32767).toShort()
                }

                if (isJumpscarePlaying) {
                    audioTrack.write(buffer, 0, numSamples)
                }
                try { audioTrack.stop() } catch (_: Exception) {}
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                try { jumpscareTrack?.release() } catch (_: Exception) {}
                jumpscareTrack = null
                isJumpscarePlaying = false
            }
        }

        try {
            if (vibrator != null && vibrator?.hasVibrator() == true) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(VibrationEffect.createOneShot(800, VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(800)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopJumpscare() {
        isJumpscarePlaying = false
        try {
            jumpscareTrack?.stop()
            jumpscareTrack?.release()
        } catch (_: Exception) {}
        jumpscareTrack = null
        try {
            vibrator?.cancel()
        } catch (_: Exception) {}
    }

    private fun stopWin() {
        isWinPlaying = false
        try {
            winTrack?.stop()
            winTrack?.release()
        } catch (_: Exception) {}
        winTrack = null
    }

    // Suara Menang Berhasil Next Level (Chiptune Victory Fanfare)
    private fun playWin() {
        stopAll()
        isWinPlaying = true

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

                winTrack = audioTrack
                audioTrack.play()

                val notes = doubleArrayOf(523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98)
                val durations = intArrayOf(120, 120, 120, 260, 150, 480)

                for (idx in notes.indices) {
                    if (!isWinPlaying) break
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
                    if (isWinPlaying) {
                        audioTrack.write(buffer, 0, numSamples)
                    }
                }

                try { audioTrack.stop() } catch (_: Exception) {}
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                try { winTrack?.release() } catch (_: Exception) {}
                winTrack = null
                isWinPlaying = false
            }
        }
    }

    // Efek suara gesekan halaman buku.
    private fun playPageTurn() {
        thread {
            var audioTrack: AudioTrack? = null
            try {
                val sampleRate = 22050
                val durationMs = 420
                val sampleCount = sampleRate * durationMs / 1000
                val minBufferSize = AudioTrack.getMinBufferSize(
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AudioFormat.ENCODING_PCM_16BIT
                )
                audioTrack = AudioTrack.Builder()
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
                    .setBufferSizeInBytes(maxOf(minBufferSize, sampleCount * 2))
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .build()

                val samples = ShortArray(sampleCount)
                var seed = 0x2468ACE
                var lowPass = 0.0
                for (i in samples.indices) {
                    seed = seed xor (seed shl 13)
                    seed = seed xor (seed ushr 17)
                    seed = seed xor (seed shl 5)
                    val noise = seed.toDouble() / Int.MAX_VALUE
                    lowPass += (noise - lowPass) * .24

                    val t = i.toDouble() / sampleCount
                    val envelope = minOf(1.0, t * 9) * minOf(1.0, (1 - t) * 5)
                    val flutter = .72 + .28 * sin(2.0 * Math.PI * 13 * t)
                    val rustle = (noise * .62 + lowPass * .38) * 2300 * envelope * flutter
                    samples[i] = rustle.toInt().coerceIn(-32767, 32767).toShort()
                }

                audioTrack.play()
                audioTrack.write(samples, 0, samples.size)
                audioTrack.stop()
            } catch (_: Exception) {
                // Keep the splash screen working if audio is unavailable.
            } finally {
                audioTrack?.release()
            }
        }
    }

    // Suara "Ting" singkat (notifikasi / item diambil)
    private fun playTing() {
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

                val notes = doubleArrayOf(1046.50, 1567.98)
                val durations = intArrayOf(70, 160)

                for (idx in notes.indices) {
                    val freq = notes[idx]
                    val durationMs = durations[idx]
                    val numSamples = (sampleRate * (durationMs / 1000.0)).toInt()
                    val buffer = ShortArray(numSamples)

                    for (i in 0 until numSamples) {
                        val t = i.toDouble() / sampleRate
                        val envelope = if (i < 100) i / 100.0 else Math.exp(-3.0 * (i.toDouble() / numSamples))
                        val wave = sin(2.0 * Math.PI * freq * t)
                        val sample = wave * 9000.0 * envelope
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
        stopWin()
    }

    override fun onDestroy() {
        stopAll()
        super.onDestroy()
    }
}
