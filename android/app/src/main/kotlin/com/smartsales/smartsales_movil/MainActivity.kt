package com.smartsales.smartsales_movil


import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), RecognitionListener {

    private val CHANNEL = "smart_sales/voice"
    private val REQUEST_RECORD_AUDIO = 1001

    private var speechRecognizer: SpeechRecognizer? = null
    private var resultCallback: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startListening" -> {
                        startListening(result)
                    }
                    "stopListening" -> {
                        stopListening()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startListening(result: MethodChannel.Result) {
        // Guardamos el callback para devolver el texto luego
        resultCallback = result

        // Permiso de micrófono
        if (!hasAudioPermission()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                REQUEST_RECORD_AUDIO
            )
            resultCallback?.error("no_permission", "Mic permission not granted", null)
            resultCallback = null
            return
        }

        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            resultCallback?.error("no_recognizer", "Speech recognizer not available", null)
            resultCallback = null
            return
        }

        if (speechRecognizer == null) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
            speechRecognizer?.setRecognitionListener(this)
        }

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "es-ES") // puedes probar "es-BO"
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }

        speechRecognizer?.startListening(intent)
    }

    private fun stopListening() {
        speechRecognizer?.stopListening()
    }

    private fun hasAudioPermission(): Boolean {
        val status = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO
        )
        return status == PackageManager.PERMISSION_GRANTED
    }

    // ==== RecognitionListener ====

    override fun onReadyForSpeech(params: Bundle?) {}
    override fun onBeginningOfSpeech() {}
    override fun onRmsChanged(rmsdB: Float) {}
    override fun onBufferReceived(buffer: ByteArray?) {}
    override fun onEndOfSpeech() {}

    override fun onError(error: Int) {
        resultCallback?.error("speech_error", "Error code: $error", null)
        resultCallback = null
    }

    override fun onResults(results: Bundle?) {
        val matches = results
            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)

        val text = matches?.firstOrNull() ?: ""
        resultCallback?.success(text)
        resultCallback = null
    }

    override fun onPartialResults(partialResults: Bundle?) {}
    override fun onEvent(eventType: Int, params: Bundle?) {}

    override fun onDestroy() {
        super.onDestroy()
        speechRecognizer?.destroy()
        speechRecognizer = null
    }
}
