package com.zm.bill

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "com.zm.bill/public_storage"
    private val fileHashChannelName = "com.zm.bill/file_hash"
    private val imageOptimizerChannelName = "com.zm.bill/image_optimizer"
    private val permissionRequestCode = 7012
    private val fileHashRequestCode = 7013
    private val imagePickRequestCode = 7014
    private val imageWritePermissionRequestCode = 7015
    private val maxHashFileBytes = 512L * 1024L * 1024L
    private val maxImageInputBytes = 20L * 1024L * 1024L
    private val maxImagePixels = 24_000_000L
    private val maxImageTargetSide = 4096
    private var pendingCall: MethodCall? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingHashResult: MethodChannel.Result? = null
    private var pendingHashAlgorithm: String? = null
    private val hashExecutor = Executors.newSingleThreadExecutor()
    private var pendingImagePickResult: MethodChannel.Result? = null
    private var pendingImageSaveResult: MethodChannel.Result? = null
    private var selectedImageFile: File? = null
    private var selectedImageName = "image"
    private var selectedImageSize = 0L
    private var selectedImageWidth = 0
    private var selectedImageHeight = 0
    private var optimizedImageFile: File? = null
    private var optimizedImageFormat = "jpeg"
    private var imageBusy = false
    private val imageExecutor = Executors.newSingleThreadExecutor()

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, imageOptimizerChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickImage" -> pickImage(result)
                    "optimizeImage" -> optimizeImage(call, result)
                    "saveOptimizedImage" -> requestImageSave(result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == imagePickRequestCode) {
            handleImagePick(resultCode, data)
            return
        }
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

    private fun pickImage(result: MethodChannel.Result) {
        if (imageBusy || pendingImagePickResult != null) {
            result.error("busy", "An image operation is already running", null)
            return
        }
        pendingImagePickResult = result
        // 系统文档选择器只授予一张图片的读取能力，不申请全部文件访问权限。
        startActivityForResult(
            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "image/*"
                putExtra(
                    Intent.EXTRA_MIME_TYPES,
                    arrayOf("image/jpeg", "image/png", "image/webp"),
                )
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            },
            imagePickRequestCode,
        )
    }

    private fun handleImagePick(resultCode: Int, data: Intent?) {
        val result = pendingImagePickResult ?: return
        pendingImagePickResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        imageBusy = true
        imageExecutor.execute {
            var inputFile: File? = null
            try {
                val metadata = queryFileMetadata(uri)
                if (metadata.second != null && metadata.second!! > maxImageInputBytes) {
                    throw ImageTooLargeException()
                }
                inputFile = File(cacheDir, "image_optimizer_input.tmp")
                inputFile.delete()
                val copiedBytes = copySelectedImage(uri, inputFile)
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(inputFile.absolutePath, bounds)
                val supportedTypes = setOf("image/jpeg", "image/png", "image/webp")
                if (bounds.outWidth <= 0 || bounds.outHeight <= 0 ||
                    bounds.outMimeType !in supportedTypes
                ) {
                    throw UnsupportedImageException()
                }
                val pixels = bounds.outWidth.toLong() * bounds.outHeight.toLong()
                if (pixels > maxImagePixels) throw ImagePixelsExceededException()
                val orientation = readExifOrientation(inputFile)
                val swapsSides = orientation in setOf(
                    ExifInterface.ORIENTATION_TRANSPOSE,
                    ExifInterface.ORIENTATION_ROTATE_90,
                    ExifInterface.ORIENTATION_TRANSVERSE,
                    ExifInterface.ORIENTATION_ROTATE_270,
                )
                val displayWidth = if (swapsSides) bounds.outHeight else bounds.outWidth
                val displayHeight = if (swapsSides) bounds.outWidth else bounds.outHeight

                selectedImageFile?.delete()
                optimizedImageFile?.delete()
                optimizedImageFile = null
                selectedImageFile = inputFile
                inputFile = null
                selectedImageName = metadata.first
                selectedImageSize = copiedBytes
                selectedImageWidth = displayWidth
                selectedImageHeight = displayHeight
                runOnUiThread {
                    imageBusy = false
                    result.success(
                        mapOf(
                            "name" to selectedImageName,
                            "size" to selectedImageSize,
                            "width" to selectedImageWidth,
                            "height" to selectedImageHeight,
                        ),
                    )
                }
            } catch (_: ImageTooLargeException) {
                inputFile?.delete()
                finishImageError(result, "image_too_large", "Image exceeds the 20 MB limit")
            } catch (_: ImagePixelsExceededException) {
                inputFile?.delete()
                finishImageError(result, "too_many_pixels", "Image exceeds the 24 megapixel limit")
            } catch (_: UnsupportedImageException) {
                inputFile?.delete()
                finishImageError(result, "unsupported_format", "Unsupported image format")
            } catch (_: Exception) {
                inputFile?.delete()
                finishImageError(result, "read_failed", "Unable to read selected image")
            }
        }
    }

    private fun copySelectedImage(uri: Uri, target: File): Long {
        var total = 0L
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(target, false).use { output ->
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                while (true) {
                    val read = input.read(buffer)
                    if (read < 0) break
                    total += read
                    // 文件提供方可能不报告大小，复制过程中仍强制执行上限。
                    if (total > maxImageInputBytes) throw ImageTooLargeException()
                    output.write(buffer, 0, read)
                }
            }
        } ?: throw IllegalStateException("Unable to open selected image")
        return total
    }

    private fun optimizeImage(call: MethodCall, result: MethodChannel.Result) {
        val source = selectedImageFile
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        val quality = call.argument<Int>("quality")
        val format = call.argument<String>("format")
        if (source == null || !source.exists()) {
            result.error("no_image", "Select an image first", null)
            return
        }
        if (width == null || height == null || quality == null || format == null ||
            width !in 1..maxImageTargetSide || height !in 1..maxImageTargetSide ||
            quality !in 10..100 || format !in setOf("jpeg", "png", "webp")
        ) {
            result.error("invalid_arguments", "Invalid image settings", null)
            return
        }
        if (imageBusy) {
            result.error("busy", "An image operation is already running", null)
            return
        }
        imageBusy = true
        imageExecutor.execute {
            var decoded: Bitmap? = null
            var oriented: Bitmap? = null
            var scaled: Bitmap? = null
            var flattened: Bitmap? = null
            var output: File? = null
            try {
                val sampleSize = calculateImageSampleSize(width, height)
                val decodedBitmap = BitmapFactory.decodeFile(
                    source.absolutePath,
                    BitmapFactory.Options().apply { inSampleSize = sampleSize },
                )
                    ?: throw IllegalStateException("Decode failed")
                decoded = decodedBitmap
                val orientedBitmap = applyExifOrientation(
                    decodedBitmap,
                    readExifOrientation(source),
                )
                oriented = orientedBitmap
                if (orientedBitmap !== decodedBitmap) {
                    decodedBitmap.recycle()
                    decoded = null
                }
                val scaledBitmap = if (
                    orientedBitmap.width == width && orientedBitmap.height == height
                ) {
                    orientedBitmap
                } else {
                    Bitmap.createScaledBitmap(orientedBitmap, width, height, true)
                }
                scaled = scaledBitmap
                if (scaledBitmap !== orientedBitmap) {
                    orientedBitmap.recycle()
                    oriented = null
                }
                val imageToWrite = if (format == "jpeg" && scaledBitmap.hasAlpha()) {
                    Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { bitmap ->
                        Canvas(bitmap).apply {
                            drawColor(Color.WHITE)
                            drawBitmap(scaledBitmap, 0f, 0f, null)
                        }
                    }.also { flattened = it }
                } else {
                    scaledBitmap
                }
                if (imageToWrite !== scaledBitmap) {
                    scaledBitmap.recycle()
                    scaled = null
                }
                val extension = if (format == "jpeg") "jpg" else format
                output = File(cacheDir, "image_optimizer_result.$extension")
                output.delete()
                FileOutputStream(output, false).use { stream ->
                    if (!imageToWrite.compress(compressFormat(format), quality, stream)) {
                        throw IllegalStateException("Compress failed")
                    }
                }
                optimizedImageFile?.delete()
                optimizedImageFile = output
                output = null
                optimizedImageFormat = format
                val outputSize = optimizedImageFile!!.length()
                runOnUiThread {
                    imageBusy = false
                    result.success(mapOf("size" to outputSize, "width" to width, "height" to height))
                }
            } catch (_: OutOfMemoryError) {
                output?.delete()
                finishImageError(result, "memory_limit", "Not enough memory to process this image")
            } catch (_: Exception) {
                output?.delete()
                finishImageError(result, "optimize_failed", "Unable to optimize image")
            } finally {
                listOf(flattened, scaled, oriented, decoded).distinct().forEach { bitmap ->
                    if (bitmap != null && !bitmap.isRecycled) bitmap.recycle()
                }
            }
        }
    }

    private fun calculateImageSampleSize(targetWidth: Int, targetHeight: Int): Int {
        var sample = 1
        // 使用 2 的幂进行预采样，避免为小尺寸输出完整解码大图。
        while (selectedImageWidth / (sample * 2) >= targetWidth &&
            selectedImageHeight / (sample * 2) >= targetHeight
        ) {
            sample *= 2
        }
        return sample
    }

    private fun readExifOrientation(file: File): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                ExifInterface(file.absolutePath).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL,
                )
            } catch (_: Exception) {
                ExifInterface.ORIENTATION_NORMAL
            }
        } else {
            ExifInterface.ORIENTATION_NORMAL
        }

    private fun applyExifOrientation(source: Bitmap, orientation: Int): Bitmap {
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.setRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.setScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.setRotate(90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.setRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.setRotate(-90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.setRotate(-90f)
            else -> return source
        }
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }

    @Suppress("DEPRECATION")
    private fun compressFormat(format: String): Bitmap.CompressFormat = when (format) {
        "png" -> Bitmap.CompressFormat.PNG
        "webp" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Bitmap.CompressFormat.WEBP_LOSSY
        } else {
            Bitmap.CompressFormat.WEBP
        }
        else -> Bitmap.CompressFormat.JPEG
    }

    private fun requestImageSave(result: MethodChannel.Result) {
        if (optimizedImageFile?.exists() != true) {
            result.error("no_result", "Optimize an image first", null)
            return
        }
        if (imageBusy || pendingImageSaveResult != null) {
            result.error("busy", "An image operation is already running", null)
            return
        }
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P &&
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            pendingImageSaveResult = result
            requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                imageWritePermissionRequestCode,
            )
            return
        }
        saveOptimizedImage(result)
    }

    private fun saveOptimizedImage(result: MethodChannel.Result) {
        val source = optimizedImageFile
        if (source == null || !source.exists()) {
            result.error("no_result", "Optimize an image first", null)
            return
        }
        imageBusy = true
        imageExecutor.execute {
            try {
                val fileName = buildOptimizedImageName()
                val location = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    saveImageWithMediaStore(source, fileName)
                } else {
                    saveImageLegacy(source, fileName)
                }
                runOnUiThread {
                    imageBusy = false
                    result.success(location)
                }
            } catch (_: Exception) {
                finishImageError(result, "save_failed", "Unable to save optimized image")
            }
        }
    }

    private fun buildOptimizedImageName(): String {
        val base = selectedImageName.substringBeforeLast('.', selectedImageName)
            .replace(Regex("[^\\p{L}\\p{N}._-]"), "_")
            .trim('.', '_')
            .take(48)
            .ifBlank { "image" }
        val extension = if (optimizedImageFormat == "jpeg") "jpg" else optimizedImageFormat
        return "${base}_optimized_${System.currentTimeMillis()}.$extension"
    }

    private fun saveImageWithMediaStore(source: File, fileName: String): String {
        val relativePath = "${Environment.DIRECTORY_PICTURES}/ZM工具箱/"
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/$optimizedImageFormat")
            put(MediaStore.Images.Media.RELATIVE_PATH, relativePath)
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("MediaStore insert failed")
        try {
            contentResolver.openOutputStream(uri, "w")?.use { output ->
                FileInputStream(source).use { input -> input.copyTo(output) }
            } ?: throw IllegalStateException("MediaStore stream failed")
            contentResolver.update(
                uri,
                ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) },
                null,
                null,
            )
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }
        return "/storage/emulated/0/Pictures/ZM工具箱/$fileName"
    }

    @Suppress("DEPRECATION")
    private fun saveImageLegacy(source: File, fileName: String): String {
        val pictures = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
        val base = File(pictures, "ZM工具箱")
        if (!base.exists() && !base.mkdirs()) throw IllegalStateException("mkdir failed")
        val canonicalBase = base.canonicalFile
        val target = File(canonicalBase, fileName).canonicalFile
        if (target.parentFile != canonicalBase) throw SecurityException("Unsafe path")
        FileInputStream(source).use { input ->
            FileOutputStream(target, false).use { output -> input.copyTo(output) }
        }
        return target.absolutePath
    }

    private fun finishImageError(result: MethodChannel.Result, code: String, message: String) {
        runOnUiThread {
            imageBusy = false
            result.error(code, message, null)
        }
    }

    private class ImageTooLargeException : Exception()
    private class ImagePixelsExceededException : Exception()
    private class UnsupportedImageException : Exception()

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
        imageExecutor.shutdownNow()
        pendingHashResult?.error("cancelled", "Activity was closed", null)
        pendingHashResult = null
        pendingHashAlgorithm = null
        pendingImagePickResult?.error("cancelled", "Activity was closed", null)
        pendingImagePickResult = null
        pendingImageSaveResult?.error("cancelled", "Activity was closed", null)
        pendingImageSaveResult = null
        selectedImageFile?.delete()
        selectedImageFile = null
        optimizedImageFile?.delete()
        optimizedImageFile = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == imageWritePermissionRequestCode) {
            val imageResult = pendingImageSaveResult
            pendingImageSaveResult = null
            if (imageResult != null) {
                if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
                    saveOptimizedImage(imageResult)
                } else {
                    imageResult.error("permission_denied", "Storage permission was denied", null)
                }
            }
            return
        }
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
