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
            mVisualizer = Visualizer(sessionId).apply {
                captureSize = Visualizer.getCaptureSizeRange()[1]
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
            Log.d("ExternalVisualizer", "Visualizer attached to session $sessionId for player $playerId")
        } catch (e: Exception) {
            Log.e("ExternalVisualizer", "Error attaching visualizer: ${e.message}")
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
