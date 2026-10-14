package com.victor.stickerfast

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import java.io.ByteArrayOutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "stickerfast/whatsapp"
        private const val ADD_PACK_REQUEST = 200
        private const val ENABLE_STICKER_PACK =
            "com.whatsapp.intent.action.ENABLE_STICKER_PACK"

        private const val CONSUMER_PACKAGE = "com.whatsapp"
        private const val BUSINESS_PACKAGE = "com.whatsapp.w4b"
        private const val CONSUMER_WHITELIST =
            "com.whatsapp.provider.sticker_whitelist_check"
        private const val BUSINESS_WHITELIST =
            "com.whatsapp.w4b.provider.sticker_whitelist_check"
    }

    private var pendingAddPackResult: MethodChannel.Result? = null

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
                            "PACK_INVALID",
                            "Identificador ou nome do pacote esta vazio.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        validateStickerPack(identifier)
                    } catch (e: Exception) {
                        result.error(
                            "PACK_INVALID",
                            e.message ?: "O pacote nao passou na validacao local.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    openWhatsAppPack(identifier, name, result)
                }

                "compressWebp" -> {
                    val bytes = call.argument<ByteArray>("pngBytes")
                    val quality = call.argument<Int>("quality") ?: 80
                    if (bytes == null || bytes.isEmpty()) {
                        result.error(
                            "INVALID_IMAGE",
                            "Imagem vazia.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    val bitmap = BitmapFactory.decodeByteArray(
                        bytes,
                        0,
                        bytes.size,
                    )
                    if (bitmap == null) {
                        result.error(
                            "INVALID_IMAGE",
                            "Nao foi possivel decodificar a imagem.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        val stream = ByteArrayOutputStream()
                        @Suppress("DEPRECATION")
                        val format =
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                Bitmap.CompressFormat.WEBP_LOSSY
                            } else {
                                Bitmap.CompressFormat.WEBP
                            }

                        val ok = bitmap.compress(
                            format,
                            quality.coerceIn(0, 100),
                            stream,
                        )

                        if (!ok) {
                            result.error(
                                "WEBP_FAILED",
                                "Falha ao comprimir WebP.",
                                null,
                            )
                        } else {
                            result.success(stream.toByteArray())
                        }
                    } finally {
                        bitmap.recycle()
                    }
                }

                "notifyStickerDataChanged" -> {
                    notifyStickerProvider()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun notifyStickerProvider() {
        val authority = "$packageName.stickercontentprovider"
        contentResolver.notifyChange(
            Uri.parse("content://$authority/metadata"),
            null,
        )
    }

    private fun openWhatsAppPack(
        identifier: String,
        name: String,
        result: MethodChannel.Result,
    ) {
        if (pendingAddPackResult != null) {
            result.error(
                "EXPORT_BUSY",
                "Ja existe uma exportacao em andamento.",
                null,
            )
            return
        }

        val installed = listOf(CONSUMER_PACKAGE, BUSINESS_PACKAGE)
            .filter { packageManager.getLaunchIntentForPackage(it) != null }

        if (installed.isEmpty()) {
            result.error(
                "WHATSAPP_NOT_INSTALLED",
                "WhatsApp nao encontrado.",
                null,
            )
            return
        }

        val authority = "$packageName.stickercontentprovider"
        val missingPack = installed.filterNot { targetPackage ->
            isPackWhitelisted(targetPackage, authority, identifier)
        }

        if (missingPack.isEmpty()) {
            notifyStickerProvider()
            result.success(mapOf("status" to "updated"))
            return
        }

        val baseIntent = Intent(ENABLE_STICKER_PACK).apply {
            putExtra("sticker_pack_id", identifier)
            putExtra("sticker_pack_authority", authority)
            putExtra("sticker_pack_name", name)
        }

        val intent = if (missingPack.size == 1) {
            baseIntent.apply { setPackage(missingPack.first()) }
        } else {
            Intent.createChooser(baseIntent, "Adicionar figurinhas ao WhatsApp")
        }

        pendingAddPackResult = result
        try {
            startActivityForResult(intent, ADD_PACK_REQUEST)
        } catch (e: Exception) {
            pendingAddPackResult = null
            result.error(
                "WHATSAPP_OPEN_FAILED",
                e.message ?: "Falha ao abrir o WhatsApp.",
                null,
            )
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != ADD_PACK_REQUEST) return

        val pending = pendingAddPackResult ?: return
        pendingAddPackResult = null

        if (resultCode == Activity.RESULT_OK) {
            pending.success(mapOf("status" to "added"))
            return
        }

        val validationError = data?.getStringExtra("validation_error")
        if (!validationError.isNullOrBlank()) {
            pending.error(
                "WHATSAPP_VALIDATION",
                validationError,
                null,
            )
        } else {
            pending.error(
                "WHATSAPP_CANCELED",
                "O WhatsApp nao confirmou a adicao do pacote.",
                null,
            )
        }
    }

    private fun isPackWhitelisted(
        targetPackage: String,
        authority: String,
        identifier: String,
    ): Boolean {
        val whitelistAuthority = when (targetPackage) {
            CONSUMER_PACKAGE -> CONSUMER_WHITELIST
            BUSINESS_PACKAGE -> BUSINESS_WHITELIST
            else -> return false
        }

        return try {
            val uri = Uri.Builder()
                .scheme("content")
                .authority(whitelistAuthority)
                .appendPath("is_whitelisted")
                .appendQueryParameter("authority", authority)
                .appendQueryParameter("identifier", identifier)
                .build()

            contentResolver.query(
                uri,
                null,
                null,
                null,
                null,
            )?.use { cursor ->
                if (!cursor.moveToFirst()) return false
                val index = cursor.getColumnIndex("result")
                index >= 0 && cursor.getInt(index) == 1
            } ?: false
        } catch (_: Exception) {
            false
        }
    }

    private fun validateStickerPack(identifier: String) {
        val authority = "$packageName.stickercontentprovider"
        val metadataUri =
            Uri.parse("content://$authority/metadata/$identifier")

        val trayFile = contentResolver.query(
            metadataUri,
            null,
            null,
            null,
            null,
        )?.use { cursor ->
            require(cursor.moveToFirst()) {
                "O ContentProvider nao encontrou o pacote $identifier."
            }

            val idIndex = cursor.getColumnIndex("sticker_pack_identifier")
            val nameIndex = cursor.getColumnIndex("sticker_pack_name")
            val publisherIndex = cursor.getColumnIndex("sticker_pack_publisher")
            val trayIndex = cursor.getColumnIndex("sticker_pack_icon")
            val versionIndex = cursor.getColumnIndex("image_data_version")

            require(
                idIndex >= 0 &&
                    nameIndex >= 0 &&
                    publisherIndex >= 0 &&
                    trayIndex >= 0 &&
                    versionIndex >= 0
            ) {
                "Metadados do pacote estao incompletos."
            }

            require(cursor.getString(idIndex) == identifier) {
                "Identificador do pacote nao corresponde ao solicitado."
            }
            require(!cursor.getString(nameIndex).isNullOrBlank()) {
                "Nome do pacote esta vazio."
            }
            require(!cursor.getString(publisherIndex).isNullOrBlank()) {
                "Autor do pacote esta vazio."
            }
            require(!cursor.getString(versionIndex).isNullOrBlank()) {
                "image_data_version esta vazio."
            }

            cursor.getString(trayIndex)
        } ?: throw IllegalStateException(
            "Nao foi possivel consultar os metadados do pacote.",
        )

        require(!trayFile.isNullOrBlank()) {
            "Icone do pacote esta vazio."
        }
        validateAsset(
            authority = authority,
            identifier = identifier,
            fileName = trayFile,
            tray = true,
        )

        val stickersUri =
            Uri.parse("content://$authority/stickers/$identifier")

        var count = 0
        contentResolver.query(
            stickersUri,
            null,
            null,
            null,
            null,
        )?.use { cursor ->
            val fileIndex = cursor.getColumnIndex("sticker_file_name")
            val emojiIndex = cursor.getColumnIndex("sticker_emoji")
            require(fileIndex >= 0 && emojiIndex >= 0) {
                "Lista de figurinhas retornou colunas invalidas."
            }

            while (cursor.moveToNext()) {
                count++
                val fileName = cursor.getString(fileIndex)
                val emoji = cursor.getString(emojiIndex)

                require(!fileName.isNullOrBlank()) {
                    "Uma figurinha esta sem nome de arquivo."
                }
                require(!emoji.isNullOrBlank()) {
                    "A figurinha $fileName esta sem emoji associado."
                }

                validateAsset(
                    authority = authority,
                    identifier = identifier,
                    fileName = fileName,
                    tray = false,
                )
            }
        } ?: throw IllegalStateException(
            "Nao foi possivel consultar as figurinhas do pacote.",
        )

        require(count in 3..30) {
            "O pacote precisa ter entre 3 e 30 figurinhas; atualmente tem $count."
        }
    }

    private fun validateAsset(
        authority: String,
        identifier: String,
        fileName: String,
        tray: Boolean,
    ) {
        val uri = Uri.parse(
            "content://$authority/stickers_asset/$identifier/$fileName",
        )

        val bytes = contentResolver.openInputStream(uri)?.use {
            it.readBytes()
        } ?: throw IllegalStateException(
            "Nao foi possivel abrir o arquivo $fileName.",
        )

        if (tray) {
            require(bytes.size <= 50 * 1024) {
                "O icone do pacote ultrapassa 50 KB."
            }
            require(fileName.endsWith(".png", ignoreCase = true)) {
                "O icone do pacote precisa ser PNG."
            }
        } else {
            require(bytes.size <= 100 * 1024) {
                "A figurinha $fileName ultrapassa 100 KB."
            }
            require(fileName.endsWith(".webp", ignoreCase = true)) {
                "A figurinha $fileName precisa ser WebP."
            }
            require(isWebP(bytes)) {
                "O arquivo $fileName nao e um WebP valido."
            }
        }

        val bitmap = BitmapFactory.decodeByteArray(
            bytes,
            0,
            bytes.size,
        ) ?: throw IllegalStateException(
            "Nao foi possivel ler as dimensoes de $fileName.",
        )

        try {
            if (tray) {
                require(
                    bitmap.width in 24..512 &&
                        bitmap.height in 24..512
                ) {
                    "O icone do pacote deve ter entre 24 e 512 px."
                }
            } else {
                require(bitmap.width == 512 && bitmap.height == 512) {
                    "A figurinha $fileName deve ser exatamente 512x512."
                }
            }
        } finally {
            bitmap.recycle()
        }
    }

    private fun isWebP(bytes: ByteArray): Boolean {
        if (bytes.size < 12) return false
        val riff = String(
            bytes.copyOfRange(0, 4),
            Charsets.US_ASCII,
        )
        val webp = String(
            bytes.copyOfRange(8, 12),
            Charsets.US_ASCII,
        )
        return riff == "RIFF" && webp == "WEBP"
    }
}
