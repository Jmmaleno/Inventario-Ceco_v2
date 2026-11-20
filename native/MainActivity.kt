package com.example.recuento_inventario
import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(engine: FlutterEngine) {
    super.configureFlutterEngine(engine)
    MethodChannel(engine.dartExecutor.binaryMessenger, "recuento/downloads").setMethodCallHandler { call, result ->
      if (call.method != "save") { result.notImplemented(); return@setMethodCallHandler }
      val name = call.argument<String>("name")
      val bytes = call.argument<ByteArray>("bytes")
      if (name == null || bytes == null) { result.error("ARGS", "Datos no validos", null); return@setMethodCallHandler }
      try { result.success(saveToDownloads(name, bytes)) } catch (e: Exception) { result.error("SAVE", e.message, null) }
    }
  }
  private fun saveToDownloads(name: String, bytes: ByteArray): String {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      val values = ContentValues().apply {
        put(MediaStore.Downloads.DISPLAY_NAME, name)
        put(MediaStore.Downloads.MIME_TYPE, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
        put(MediaStore.Downloads.IS_PENDING, 1)
      }
      val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: error("No se pudo crear el archivo")
      contentResolver.openOutputStream(uri)?.use { it.write(bytes) } ?: error("No se pudo escribir el archivo")
      values.clear(); values.put(MediaStore.Downloads.IS_PENDING, 0); contentResolver.update(uri, values, null, null)
      return name
    }
    @Suppress("DEPRECATION") val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
    dir.mkdirs(); val file = File(dir, name); FileOutputStream(file).use { it.write(bytes) }; return file.name
  }
}
