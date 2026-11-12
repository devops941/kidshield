package com.kidshield.child.kidshield_child

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.util.Base64
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class AppInstallReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "KidShieldInstallRecv"
    }

    private val executor = Executors.newSingleThreadExecutor()

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_PACKAGE_ADDED) return

        val replacing = intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)
        if (replacing) return // Skip app updates, only capture fresh installations

        val packageName = intent.data?.schemeSpecificPart ?: return
        if (packageName == context.packageName) return // Skip KidShield self

        Log.i(TAG, "⚡ Real-time package install detected on child phone: $packageName")

        // 🔒 IMMEDIATELY lock the newly installed app locally before child can even tap Open!
        try {
            AppBlockManager.addBlockedPackage(context, packageName)
            Log.i(TAG, "🔒 App $packageName added to instant local block guard pending parent approval")
        } catch (e: Exception) {
            Log.e(TAG, "Error adding to instant local block: ${e.message}")
        }

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isPaired = prefs.getBoolean("flutter.is_paired", false)
        val childId = prefs.getString("flutter.saved_child_id", "") ?: ""

        if (!isPaired || childId.isEmpty()) {
            Log.w(TAG, "Device not paired. Skipping install event sync.")
            return
        }

        executor.execute {
            try {
                val pm = context.packageManager
                val appInfo = pm.getApplicationInfo(packageName, 0)
                val appName = pm.getApplicationLabel(appInfo).toString()
                val icon = pm.getApplicationIcon(appInfo)
                val iconBase64 = drawableToBase64(icon)
                val versionName = try {
                    pm.getPackageInfo(packageName, 0).versionName ?: "1.0"
                } catch (_: Exception) { "1.0" }

                val jsonApp = JSONObject().apply {
                    put("packageName", packageName)
                    put("appName", appName)
                    put("icon", iconBase64)
                    put("versionName", versionName)
                    put("ageRating", "Everyone")
                }

                val appsArray = JSONArray().apply {
                    put(jsonApp)
                }

                val payload = JSONObject().apply {
                    put("childId", childId)
                    put("isNewInstall", true)
                    put("apps", appsArray)
                }

                val savedBaseUrl = prefs.getString("flutter.custom_base_url", null)
                val targetEndpoint = if (!savedBaseUrl.isNullOrEmpty()) {
                    "${savedBaseUrl.trimEnd('/')}/installed-apps/sync"
                } else {
                    "https://kidshield-1jvi.onrender.com/api/installed-apps/sync"
                }
                val url = URL(targetEndpoint)
                val conn = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    connectTimeout = 10000
                    readTimeout = 10000
                    doOutput = true
                    setRequestProperty("Content-Type", "application/json; charset=UTF-8")
                }

                OutputStreamWriter(conn.outputStream, "UTF-8").use { writer ->
                    writer.write(payload.toString())
                    writer.flush()
                }

                val responseCode = conn.responseCode
                Log.i(TAG, "New app installation synced to backend with code: $responseCode")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to sync new app install: ${e.message}", e)
            }
        }
    }

    private fun drawableToBase64(drawable: Drawable?): String {
        if (drawable == null) return ""
        return try {
            val width = if (drawable.intrinsicWidth > 0) Math.min(drawable.intrinsicWidth, 64) else 48
            val height = if (drawable.intrinsicHeight > 0) Math.min(drawable.intrinsicHeight, 64) else 48
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)

            val outputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 80, outputStream)
            Base64.encodeToString(outputStream.toByteArray(), Base64.NO_WRAP)
        } catch (_: Exception) {
            ""
        }
    }
}

