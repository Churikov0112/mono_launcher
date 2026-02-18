package com.example.mono_launcher

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Bundle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.mono_launcher/apps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledApps" -> {
                        val apps = getInstalledApps()
                        result.success(apps)
                    }
                    "openApp" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            val success = openApp(packageName)
                            if (success) {
                                result.success(null)
                            } else {
                                result.error("UNABLE_TO_OPEN", "Unable to open app", null)
                            }
                        } else {
                            result.error("INVALID_ARGUMENT", "Package name is null", null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null)
        intent.addCategory(Intent.CATEGORY_LAUNCHER)
        
        val resolveInfoList = pm.queryIntentActivities(intent, 0)
        val apps = mutableListOf<Map<String, Any>>()

        for (resolveInfo in resolveInfoList) {
            val activityInfo = resolveInfo.activityInfo
            val packageName = activityInfo.packageName
            val appName = activityInfo.loadLabel(pm).toString()
            
            // Получаем иконку приложения
            val iconBytes = getIconBytes(activityInfo.loadIcon(pm))
            
            val appInfo = mapOf(
                "name" to appName,
                "packageName" to packageName,
                "icon" to (iconBytes ?: ByteArray(0))
            )
            apps.add(appInfo)
        }

        return apps
    }

    private fun getIconBytes(drawable: Drawable): ByteArray? {
        return try {
            val bitmap: Bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 48
                val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 48
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bitmap
            }

            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun openApp(packageName: String): Boolean {
        return try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                startActivity(intent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}