package com.iammop.audio_visualizer

import android.media.audiofx.Visualizer
import android.util.Log

class ExternalVisualizer(
    val playerId: String,
    val sessionId: Int,
    private val callback: MiniAudioPlayerCallback
) {
    private var mVisualizer: Visualizer? = null

    init {
        try {
            // Try different capture sizes in case max size fails
            val captureSizes = listOf(
                Visualizer.getCaptureSizeRange()[1], // Maximum
                1024,
                512
            )
            
            var visualizerCreated = false
            for (size in captureSizes) {
                try {
                    mVisualizer = Visualizer(sessionId).apply {
                        captureSize = size
                        setDataCaptureListener(object : Visualizer.OnDataCaptureListener {
                            override fun onWaveFormDataCapture(
                                visualizer: Visualizer?,
                                waveform: ByteArray?,
                                samplingRate: Int
                            ) {
                                waveform?.let {
                                    callback.onWaveformData(playerId, wavelengthToWaveform(it))
                                }
                            }

                            override fun onFftDataCapture(
                                visualizer: Visualizer?,
                                fft: ByteArray?,
                                samplingRate: Int
                            ) {
                                fft?.let {
                                    callback.onFFTData(playerId, it)
                                }
                            }
                        }, Visualizer.getMaxCaptureRate() / 2, true, true)
                        enabled = true
                    }
                    Log.d("ExternalVisualizer", "Visualizer attached to session $sessionId for player $playerId with captureSize=$size")
                    visualizerCreated = true
                    break
                } catch (e: Exception) {
                    Log.w("ExternalVisualizer", "Failed with captureSize=$size: ${e.message}")
                    mVisualizer?.release()
                    mVisualizer = null
                }
            }
            
            if (!visualizerCreated) {
                throw RuntimeException("Could not initialize visualizer with any capture size")
            }
        } catch (e: Exception) {
            Log.e("ExternalVisualizer", "Error attaching visualizer: ${e.message}")
            throw e
        }
    }

    // Helper to mirror MiniAudioPlayer behavior if needed
    private fun wavelengthToWaveform(data: ByteArray): ByteArray {
        // Just return as is for now, MiniAudioPlayer doesn't seem to transform waveform data either
        return data
    }

    fun release() {
        mVisualizer?.let {
            it.enabled = false
            it.release()
        }
        mVisualizer = null
        Log.d("ExternalVisualizer", "Visualizer released for player $playerId")
    }
}
