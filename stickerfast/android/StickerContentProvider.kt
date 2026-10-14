package com.victor.stickerfast

import android.content.ContentProvider
import android.content.ContentValues
import android.content.res.AssetFileDescriptor
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import org.json.JSONObject
import java.io.File

class StickerContentProvider : ContentProvider() {
    companion object {
        private const val METADATA = "metadata"
        private const val STICKERS = "stickers"
        private const val STICKERS_ASSET = "stickers_asset"

        private const val PACK_ID = "sticker_pack_identifier"
        private const val PACK_NAME = "sticker_pack_name"
        private const val PACK_PUBLISHER = "sticker_pack_publisher"
        private const val PACK_ICON = "sticker_pack_icon"
        private const val ANDROID_LINK = "android_play_store_link"
        private const val IOS_LINK = "ios_app_store_link"
        private const val PUBLISHER_EMAIL = "sticker_pack_publisher_email"
        private const val PUBLISHER_WEBSITE = "sticker_pack_publisher_website"
        private const val PRIVACY_WEBSITE = "sticker_pack_privacy_policy_website"
        private const val LICENSE_WEBSITE = "sticker_pack_license_agreement_website"
        private const val IMAGE_DATA_VERSION = "image_data_version"
        private const val AVOID_CACHE = "whatsapp_will_not_cache_stickers"
        private const val ANIMATED = "animated_sticker_pack"

        private const val STICKER_FILE = "sticker_file_name"
        private const val STICKER_EMOJI = "sticker_emoji"
        private const val STICKER_A11Y = "sticker_accessibility_text"
    }

    data class Sticker(
        val fileName: String,
        val emojis: String,
        val accessibilityText: String,
    )

    data class Pack(
        val identifier: String,
        val name: String,
        val publisher: String,
        val trayImage: String,
        val imageDataVersion: String,
        val avoidCache: Boolean,
        val stickers: List<Sticker>,
    )

    private val authority: String
        get() = "${requireNotNull(context).packageName}.stickercontentprovider"

    override fun onCreate(): Boolean = true

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor {
        val segments = uri.pathSegments
        if (segments.isEmpty()) {
            throw IllegalArgumentException("Unknown URI: $uri")
        }

        val cursor = when (segments[0]) {
            METADATA -> {
                val all = loadPacks()
                val selected = if (segments.size >= 2) {
                    all.filter { it.identifier == segments[1] }
                } else {
                    all
                }
                metadataCursor(selected)
            }
            STICKERS -> {
                if (segments.size < 2) {
                    throw IllegalArgumentException("Missing sticker pack id: $uri")
                }
                stickersCursor(segments[1])
            }
            else -> throw IllegalArgumentException("Unknown URI: $uri")
        }

        cursor.setNotificationUri(requireNotNull(context).contentResolver, uri)
        return cursor
    }

    private fun metadataCursor(packs: List<Pack>): MatrixCursor {
        val cursor = MatrixCursor(
            arrayOf(
                PACK_ID,
                PACK_NAME,
                PACK_PUBLISHER,
                PACK_ICON,
                ANDROID_LINK,
                IOS_LINK,
                PUBLISHER_EMAIL,
                PUBLISHER_WEBSITE,
                PRIVACY_WEBSITE,
                LICENSE_WEBSITE,
                IMAGE_DATA_VERSION,
                AVOID_CACHE,
                ANIMATED,
            )
        )

        for (pack in packs) {
            cursor.addRow(
                arrayOf<Any?>(
                    pack.identifier,
                    pack.name,
                    pack.publisher,
                    pack.trayImage,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    pack.imageDataVersion,
                    if (pack.avoidCache) 1 else 0,
                    0,
                )
            )
        }
        return cursor
    }

    private fun stickersCursor(identifier: String): MatrixCursor {
        val cursor = MatrixCursor(
            arrayOf(STICKER_FILE, STICKER_EMOJI, STICKER_A11Y)
        )
        val pack = loadPacks().firstOrNull { it.identifier == identifier }
            ?: return cursor

        for (sticker in pack.stickers) {
            cursor.addRow(
                arrayOf<Any?>(
                    sticker.fileName,
                    sticker.emojis,
                    sticker.accessibilityText,
                )
            )
        }
        return cursor
    }

    override fun openAssetFile(uri: Uri, mode: String): AssetFileDescriptor? {
        val segments = uri.pathSegments
        if (segments.size != 3 || segments[0] != STICKERS_ASSET) {
            return null
        }

        val packId = segments[1]
        val fileName = segments[2]
        val pack = loadPacks().firstOrNull { it.identifier == packId }
            ?: return null

        val allowed = fileName == pack.trayImage ||
            pack.stickers.any { it.fileName == fileName }
        if (!allowed) return null

        val base = File(
            requireNotNull(context).applicationInfo.dataDir,
            "app_flutter/packs/$packId",
        )
        val file = File(base, fileName)

        val canonicalBase = base.canonicalFile
        val canonicalFile = file.canonicalFile
        if (!canonicalFile.path.startsWith(canonicalBase.path + File.separator)) {
            return null
        }
        if (!canonicalFile.exists()) return null

        val pfd = ParcelFileDescriptor.open(
            canonicalFile,
            ParcelFileDescriptor.MODE_READ_ONLY,
        )
        return AssetFileDescriptor(
            pfd,
            0,
            AssetFileDescriptor.UNKNOWN_LENGTH,
        )
    }

    override fun getType(uri: Uri): String {
        val segments = uri.pathSegments
        if (segments.isEmpty()) throw IllegalArgumentException("Unknown URI: $uri")

        return when (segments[0]) {
            METADATA -> if (segments.size == 1) {
                "vnd.android.cursor.dir/vnd.$authority.metadata"
            } else {
                "vnd.android.cursor.item/vnd.$authority.metadata"
            }
            STICKERS -> "vnd.android.cursor.dir/vnd.$authority.stickers"
            STICKERS_ASSET -> {
                if (segments.lastOrNull()?.endsWith(".png", ignoreCase = true) == true) {
                    "image/png"
                } else {
                    "image/webp"
                }
            }
            else -> throw IllegalArgumentException("Unknown URI: $uri")
        }
    }

    private fun loadPacks(): List<Pack> {
        val stateFile = File(
            requireNotNull(context).applicationInfo.dataDir,
            "app_flutter/sticker_state.json",
        )
        if (!stateFile.exists()) return emptyList()

        return try {
            val root = JSONObject(stateFile.readText())
            val packsJson = root.optJSONArray("packs") ?: return emptyList()
            buildList {
                for (i in 0 until packsJson.length()) {
                    val p = packsJson.getJSONObject(i)
                    val stickersJson = p.optJSONArray("stickers")
                    val stickers = buildList {
                        if (stickersJson != null) {
                            for (j in 0 until stickersJson.length()) {
                                val s = stickersJson.getJSONObject(j)
                                val emojisJson = s.optJSONArray("emojis")
                                val emojis = buildList {
                                    if (emojisJson != null) {
                                        for (k in 0 until emojisJson.length()) {
                                            add(emojisJson.optString(k))
                                        }
                                    }
                                }.filter { it.isNotBlank() }
                                    .ifEmpty { listOf("🙂") }
                                    .joinToString(",")

                                add(
                                    Sticker(
                                        fileName = s.getString("imageFileName"),
                                        emojis = emojis,
                                        accessibilityText = s.optString(
                                            "accessibilityText",
                                            "Figurinha",
                                        ),
                                    )
                                )
                            }
                        }
                    }

                    add(
                        Pack(
                            identifier = p.getString("identifier"),
                            name = p.getString("name"),
                            publisher = p.optString("publisher", "StickerFast"),
                            trayImage = p.optString("trayImageFile", "tray.png"),
                            imageDataVersion = p.optString(
                                "imageDataVersion",
                                "1",
                            ),
                            avoidCache = p.optBoolean("avoidCache", true),
                            stickers = stickers,
                        )
                    )
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? =
        throw UnsupportedOperationException()

    override fun delete(
        uri: Uri,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = throw UnsupportedOperationException()

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = throw UnsupportedOperationException()
}
