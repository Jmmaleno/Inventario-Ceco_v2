package com.example.inventario_cecosa
import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
class MainActivity:FlutterActivity(){override fun configureFlutterEngine(e:FlutterEngine){super.configureFlutterEngine(e);MethodChannel(e.dartExecutor.binaryMessenger,"cecosa/downloads").setMethodCallHandler{c,r->if(c.method!="save"){r.notImplemented();return@setMethodCallHandler};val n=c.argument<String>("name");val b=c.argument<ByteArray>("bytes");if(n==null||b==null){r.error("ARGS","Datos no validos",null);return@setMethodCallHandler};try{r.success(save(n,b))}catch(x:Exception){r.error("SAVE",x.message,null)}}}private fun save(n:String,b:ByteArray):String{if(Build.VERSION.SDK_INT>=29){val v=ContentValues().apply{put(MediaStore.Downloads.DISPLAY_NAME,n);put(MediaStore.Downloads.MIME_TYPE,"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");put(MediaStore.Downloads.RELATIVE_PATH,Environment.DIRECTORY_DOWNLOADS);put(MediaStore.Downloads.IS_PENDING,1)};val u=contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI,v)?:error("No se pudo crear");contentResolver.openOutputStream(u)?.use{it.write(b)}?:error("No se pudo escribir");v.clear();v.put(MediaStore.Downloads.IS_PENDING,0);contentResolver.update(u,v,null,null);return n};@Suppress("DEPRECATION")val d=Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);d.mkdirs();val f=File(d,n);FileOutputStream(f).use{it.write(b)};return f.name}}
