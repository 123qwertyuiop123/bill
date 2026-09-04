package com.zm.bill

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "com.zm.bill/public_storage"
    private val fileHashChannelName = "com.zm.bill/file_hash"
    private val permissionRequestCode = 7012
    private val fileHashRequestCode = 7013
    private val maxHashFileBytes = 512L * 1024L * 1024L
    private var pendingCall: MethodCall? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingHashResult: MethodChannel.Result? = null
    private var pendingHashAlgorithm: String? = null
    private val hashExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "syncTxtToDownloads") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P &&
                    checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
                    PackageManager.PERMISSION_GRANTED
                ) {
                    // 同一时间只允许一个保存请求，避免权限回调串写文件。
                    if (pendingResult != null) {
                        result.error("busy", "A storage request is already running", null)
                        return@setMethodCallHandler
                    }
                    pendingCall = call
                    pendingResult = result
                    requestPermissions(
                        arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                        permissionRequestCode,
                    )
                    return@setMethodCallHandler
                }
                syncToDownloads(call, result)
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, fileHashChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "pickAndHashFile") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val algorithm = call.argument<String>("algorithm")
                if (algorithm !in setOf("MD5", "SHA-1", "SHA-256", "SHA-512")) {
                    result.error("invalid_algorithm", "Unsupported hash algorithm", null)
                    return@setMethodCallHandler
                }
                if (pendingHashResult != null) {
                    result.error("busy", "A file hash request is already running", null)
                    return@setMethodCallHandler
                }
                pendingHashResult = result
                pendingHashAlgorithm = algorithm
                // 系统文档选择器授予单个 URI 的临时只读能力，不申请广泛存储权限。
                startActivityForResult(
                    Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    },
                    fileHashRequestCode,
                )
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != fileHashRequestCode) return
        val result = pendingHashResult ?: return
        val algorithm = pendingHashAlgorithm
        pendingHashResult = null
        pendingHashAlgorithm = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || algorithm == null) {
            result.success(null)
            return
        }

        hashExecutor.execute {
            try {
                val metadata = queryFileMetadata(uri)
                val knownSize = metadata.second
                if (knownSize != null && knownSize > maxHashFileBytes) {
                    runOnUiThread {
                        result.error("file_too_large", "Selected file is too large", null)
                    }
                    return@execute
                }
                val digest = MessageDigest.getInstance(algorithm)
                var total = 0L
                contentResolver.openInputStream(uri)?.use { input ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) break
                        total += read
                        // 即使提供方没有报告大小，也在流式读取过程中强制执行上限。
                        if (total > maxHashFileBytes) throw FileTooLargeException()
                        digest.update(buffer, 0, read)
                    }
                } ?: throw IllegalStateException("Unable to open selected file")
                val hex = digest.digest().joinToString("") { "%02x".format(it) }
                runOnUiThread {
                    result.success(
                        mapOf(
                            "name" to metadata.first,
                            "size" to total,
                            "digest" to hex,
                        ),
                    )
                }
            } catch (_: FileTooLargeException) {
                runOnUiThread {
                    result.error("file_too_large", "Selected file is too large", null)
                }
            } catch (_: Exception) {
                // 不回传 URI、路径、文件内容或原生异常细节。
                runOnUiThread {
                    result.error("read_failed", "Unable to read selected file", null)
                }
            }
        }
    }

    private fun queryFileMetadata(uri: android.net.Uri): Pair<String, Long?> {
        var name = "所选文件"
        var size: Long? = null
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                if (nameIndex >= 0) name = cursor.getString(nameIndex) ?: name
                if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) size = cursor.getLong(sizeIndex)
            }
        }
        return name.take(128) to size
    }

    private class FileTooLargeException : Exception()

    override fun onDestroy() {
        hashExecutor.shutdownNow()
        pendingHashResult?.error("cancelled", "Activity was closed", null)
        pendingHashResult = null
        pendingHashAlgorithm = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != permissionRequestCode) return
        val call = pendingCall
        val result = pendingResult
        pendingCall = null
        pendingResult = null
        if (call == null || result == null) return
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            syncToDownloads(call, result)
        } else {
            result.error("permission_denied", "Storage permission was denied", null)
        }
    }

    private fun syncToDownloads(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val fileName = call.argument<String>("fileName")
        val previousFileName = call.argument<String>("previousFileName")
        val year = call.argument<Int>("year")
        if (bytes == null || fileName == null || year == null ||
            !isSafeTxtName(fileName) ||
            (previousFileName != null && !isSafeTxtName(previousFileName)) ||
            year !in 2000..2100
        ) {
            result.error("invalid_arguments", "Invalid file metadata", null)
            return
        }

        try {
            val location = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                writeWithMediaStore(bytes, fileName, previousFileName, year)
            } else {
                writeLegacy(bytes, fileName, previousFileName, year)
            }
            result.success(location)
        } catch (_: Exception) {
            // 不向界面泄露系统路径、数据库或设备实现细节。
            result.error("write_failed", "Unable to sync public TXT", null)
        }
    }

    private fun writeWithMediaStore(
        bytes: ByteArray,
        fileName: String,
        previousFileName: String?,
        year: Int,
    ): String {
        val resolver = contentResolver
        val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
        val relativePath = "${Environment.DIRECTORY_DOWNLOADS}/bill/$year/"

        if (previousFileName != null && previousFileName != fileName) {
            findDownload(previousFileName, relativePath)?.let {
                resolver.delete(it, null, null)
            }
        }

        var uri = findDownload(fileName, relativePath)
        var newlyCreated = false
        if (uri == null) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "text/plain")
                put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("MediaStore insert failed")
            newlyCreated = true
        }

        try {
            resolver.openOutputStream(uri, "wt")?.use { it.write(bytes) }
                ?: throw IllegalStateException("MediaStore stream failed")
            if (newlyCreated) {
                resolver.update(
                    uri,
                    ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) },
                    null,
                    null,
                )
            }
        } catch (error: Exception) {
            if (newlyCreated) resolver.delete(uri, null, null)
            throw error
        }
        return "/storage/emulated/0/Download/bill/$year/$fileName"
    }

    private fun findDownload(fileName: String, relativePath: String) =
        contentResolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Downloads._ID),
            "${MediaStore.Downloads.DISPLAY_NAME}=? AND ${MediaStore.Downloads.RELATIVE_PATH}=?",
            arrayOf(fileName, relativePath),
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) null
            else ContentUris.withAppendedId(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)),
            )
        }

    @Suppress("DEPRECATION")
    private fun writeLegacy(
        bytes: ByteArray,
        fileName: String,
        previousFileName: String?,
        year: Int,
    ): String {
        val download = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val base = File(download, "bill/$year")
        if (!base.exists() && !base.mkdirs()) throw IllegalStateException("mkdir failed")
        val canonicalBase = base.canonicalFile
        val target = File(canonicalBase, fileName).canonicalFile
        if (target.parentFile != canonicalBase) throw SecurityException("Unsafe path")
        if (previousFileName != null && previousFileName != fileName) {
            val old = File(canonicalBase, previousFileName).canonicalFile
            if (old.parentFile == canonicalBase && old.exists()) old.delete()
        }
        FileOutputStream(target, false).use { it.write(bytes) }
        return target.absolutePath
    }

    private fun isSafeTxtName(name: String): Boolean =
        name.length in 5..64 &&
        name.lowercase().endsWith(".txt") &&
        !name.contains(Regex("[\\u0000-\\u001f<>:\"/\\\\|?*]")) &&
        name != "." && name != ".."
}
