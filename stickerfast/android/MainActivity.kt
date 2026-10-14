package com.victor.stickerfast

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "stickerfast/whatsapp"
        private const val ENABLE_STICKER_PACK =
            "com.whatsapp.intent.action.ENABLE_STICKER_PACK"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "addPack" -> {
                    val identifier = call.argument<String>("identifier")
                    val name = call.argument<String>("name")
                    if (identifier.isNullOrBlank() || name.isNullOrBlank()) {
                        result.error(
                            "INVALID_PACK",
                            "Pacote invalido.",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    openWhatsAppPack(identifier, name, result)
                }
                "notifyStickerDataChanged" -> {
                    val authority = "$packageName.stickercontentprovider"
                    contentResolver.notifyChange(
                        Uri.parse("content://$authority/metadata"),
                        null,
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openWhatsAppPack(
        identifier: String,
        name: String,
        result: MethodChannel.Result,
    ) {
        val candidates = listOf("com.whatsapp", "com.whatsapp.w4b")
        val target = candidates.firstOrNull { candidate ->
            packageManager.getLaunchIntentForPackage(candidate) != null
        }

        if (target == null) {
            result.error(
                "WHATSAPP_NOT_INSTALLED",
                "WhatsApp nao encontrado.",
                null,
            )
            return
        }

        val intent = Intent(ENABLE_STICKER_PACK).apply {
            setPackage(target)
            putExtra("sticker_pack_id", identifier)
            putExtra(
                "sticker_pack_authority",
                "$packageName.stickercontentprovider",
            )
            putExtra("sticker_pack_name", name)
        }

        try {
            startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "WHATSAPP_OPEN_FAILED",
                e.message ?: "Falha ao abrir o WhatsApp.",
                null,
            )
        }
    }
}
