package com.kidshield.parent.kidshield_parent

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.location.Address
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Base64
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Locale
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val GPS_CHANNEL = "com.kidshield.parent/gps"
    private val APPS_CHANNEL = "com.kidshield.parent/apps"
    private val EMERGENCY_CHANNEL = "com.kidshield.parent/emergency"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var sirenRingtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Parent GPS Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    val fine = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    val coarse = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    result.success(fine || coarse)
                }
                "requestPermission" -> {
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                        1001
                    )
                    result.success(true)
                }
                "getRealLocation" -> {
                    fetchRealLocation(result)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Apps & Battery Channel for physical device fallback
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    fetchInstalledApps(result)
                }
                "getBatteryLevel" -> {
                    result.success(getBatteryPercentage())
                }
                else -> result.notImplemented()
            }
        }

        // 3. Emergency SOS Action Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EMERGENCY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openDialer" -> {
                    val number = call.argument<String>("number") ?: "112"
                    try {
                        val dialIntent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$number")).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(dialIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DIAL_ERROR", e.localizedMessage, null)
                    }
                }
                "openNavigation" -> {
                    val lat = call.argument<Double>("latitude") ?: 0.0
                    val lng = call.argument<Double>("longitude") ?: 0.0
                    val label = call.argument<String>("label") ?: "Child Location"
                    try {
                        val navUri = Uri.parse("google.navigation:q=$lat,$lng&mode=d")
                        val mapIntent = Intent(Intent.ACTION_VIEW, navUri).apply {
                            setPackage("com.google.android.apps.maps")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        if (mapIntent.resolveActivity(packageManager) != null) {
                            startActivity(mapIntent)
                        } else {
                            val geoUri = Uri.parse("geo:$lat,$lng?q=$lat,$lng($label)")
                            val fallbackIntent = Intent(Intent.ACTION_VIEW, geoUri).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(fallbackIntent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("MAP_ERROR", e.localizedMessage, null)
                    }
                }
                "playSiren" -> {
                    playSiren()
                    result.success(true)
                }
                "stopSiren" -> {
                    stopSiren()
                    result.success(true)
                }
                "vibrateAlert" -> {
                    vibrateAlert()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getBatteryPercentage(): Int {
        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    private fun fetchInstalledApps(result: MethodChannel.Result) {
        executor.execute {
            try {
                val pm = packageManager
                val intent = Intent(Intent.ACTION_MAIN, null).apply {
                    addCategory(Intent.CATEGORY_LAUNCHER)
                }
                val resolveInfos = pm.queryIntentActivities(intent, 0)
                val appsList = ArrayList<Map<String, Any>>()

                for (info in resolveInfos) {
                    val pkgName = info.activityInfo.packageName
                    if (pkgName == packageName) continue

                    val appName = info.loadLabel(pm).toString()
                    val iconDrawable = info.loadIcon(pm)
                    val iconBase64 = drawableToBase64(iconDrawable)

                    val appMap = HashMap<String, Any>()
                    appMap["packageName"] = pkgName
                    appMap["appName"] = appName
                    appMap["icon"] = iconBase64
                    appMap["versionName"] = try {
                        pm.getPackageInfo(pkgName, 0).versionName ?: "1.0"
                    } catch (_: Exception) { "1.0" }

                    appsList.add(appMap)
                }

                mainHandler.post {
                    result.success(appsList)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("APPS_ERROR", e.localizedMessage ?: "Unknown error", null)
                }
            }
        }
    }

    private fun drawableToBase64(drawable: Drawable): String {
        return try {
            val width = if (drawable.intrinsicWidth > 0) Math.min(drawable.intrinsicWidth, 96) else 96
            val height = if (drawable.intrinsicHeight > 0) Math.min(drawable.intrinsicHeight, 96) else 96
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)

            val outputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 85, outputStream)
            Base64.encodeToString(outputStream.toByteArray(), Base64.NO_WRAP)
        } catch (_: Exception) {
            ""
        }
    }

    private fun fetchRealLocation(result: MethodChannel.Result) {
        val fine = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val coarse = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

        if (!fine && !coarse) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                1001
            )
            result.error("PERMISSION_DENIED", "Location permission not granted. Please allow location access.", null)
            return
        }

        try {
            val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager

            val isGpsEnabled = lm.isProviderEnabled(LocationManager.GPS_PROVIDER)
            val isNetworkEnabled = lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)

            if (!isGpsEnabled && !isNetworkEnabled) {
                result.error("LOCATION_DISABLED", "Location services are turned off. Please turn on GPS.", null)
                return
            }

            var bestLoc: Location? = null
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && lm.allProviders.contains(LocationManager.FUSED_PROVIDER)) {
                try {
                    val fused = lm.getLastKnownLocation(LocationManager.FUSED_PROVIDER)
                    if (fused != null) bestLoc = fused
                } catch (_: Exception) {}
            }
            if (isGpsEnabled) {
                try {
                    val loc = lm.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                    if (loc != null && (bestLoc == null || loc.time > bestLoc.time)) bestLoc = loc
                } catch (_: Exception) {}
            }
            if (isNetworkEnabled) {
                try {
                    val loc = lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
                    if (loc != null && (bestLoc == null || loc.time > bestLoc.time)) bestLoc = loc
                } catch (_: Exception) {}
            }

            val provider = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && lm.allProviders.contains(LocationManager.FUSED_PROVIDER) && lm.isProviderEnabled(LocationManager.FUSED_PROVIDER)) {
                LocationManager.FUSED_PROVIDER
            } else if (isNetworkEnabled) {
                LocationManager.NETWORK_PROVIDER
            } else {
                LocationManager.GPS_PROVIDER
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                lm.getCurrentLocation(provider, null, executor) { location ->
                    val finalLoc = location ?: bestLoc
                    if (finalLoc != null) {
                        resolveAndReturn(finalLoc, result)
                    } else {
                        mainHandler.post {
                            result.error("LOCATION_NULL", "Unable to get GPS fix. Please ensure device has clear sky view.", null)
                        }
                    }
                }
            } else if (bestLoc != null) {
                resolveAndReturn(bestLoc, result)
            } else {
                var responded = false
                val listener = object : LocationListener {
                    override fun onLocationChanged(location: Location) {
                        if (!responded) {
                            responded = true
                            try { lm.removeUpdates(this) } catch (_: Exception) {}
                            resolveAndReturn(location, result)
                        }
                    }
                    override fun onProviderDisabled(provider: String) {}
                    override fun onProviderEnabled(provider: String) {}
                    @Deprecated("Deprecated in Java")
                    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                }

                lm.requestSingleUpdate(provider, listener, Looper.getMainLooper())

                mainHandler.postDelayed({
                    if (!responded) {
                        responded = true
                        try { lm.removeUpdates(listener) } catch (_: Exception) {}
                        result.error("TIMEOUT", "Location fix timed out. Make sure GPS is enabled.", null)
                    }
                }, 6000)
            }
        } catch (e: Exception) {
            result.error("GPS_ERROR", e.localizedMessage ?: "Unknown GPS error", null)
        }
    }

    private fun resolveAndReturn(loc: Location, result: MethodChannel.Result) {
        executor.execute {
            var addressText = "GPS: ${String.format(Locale.US, "%.4f", loc.latitude)}, ${String.format(Locale.US, "%.4f", loc.longitude)}"
            try {
                if (Geocoder.isPresent()) {
                    val geocoder = Geocoder(this, Locale.getDefault())
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        geocoder.getFromLocation(loc.latitude, loc.longitude, 1) { addresses ->
                            var finalAddr = addressText
                            if (!addresses.isNullOrEmpty()) {
                                val a = addresses[0]
                                val items = mutableListOf<String>()
                                if (!a.subLocality.isNullOrBlank()) items.add(a.subLocality)
                                if (!a.locality.isNullOrBlank()) items.add(a.locality)
                                if (!a.adminArea.isNullOrBlank()) items.add(a.adminArea)
                                if (items.isNotEmpty()) {
                                    finalAddr = items.joinToString(", ")
                                } else if (!a.getAddressLine(0).isNullOrBlank()) {
                                    finalAddr = a.getAddressLine(0)
                                }
                            }
                            sendResult(loc, finalAddr, result)
                        }
                        return@execute
                    } else {
                        @Suppress("DEPRECATION")
                        val addresses: List<Address>? = geocoder.getFromLocation(loc.latitude, loc.longitude, 1)
                        if (!addresses.isNullOrEmpty()) {
                            val a = addresses[0]
                            val items = mutableListOf<String>()
                            if (!a.subLocality.isNullOrBlank()) items.add(a.subLocality)
                            if (!a.locality.isNullOrBlank()) items.add(a.locality)
                            if (!a.adminArea.isNullOrBlank()) items.add(a.adminArea)
                            if (items.isNotEmpty()) {
                                addressText = items.joinToString(", ")
                            } else if (!a.getAddressLine(0).isNullOrBlank()) {
                                addressText = a.getAddressLine(0)
                            }
                        }
                    }
                }
            } catch (_: Exception) {}

            sendResult(loc, addressText, result)
        }
    }

    private fun sendResult(loc: Location, addressText: String, result: MethodChannel.Result) {
        val resultMap = HashMap<String, Any>()
        resultMap["latitude"] = loc.latitude
        resultMap["longitude"] = loc.longitude
        resultMap["accuracy"] = loc.accuracy.toDouble()
        resultMap["speed"] = loc.speed.toDouble()
        resultMap["address"] = addressText

        mainHandler.post {
            result.success(resultMap)
        }
    }

    private fun playSiren() {
        try {
            if (sirenRingtone == null) {
                val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                sirenRingtone = RingtoneManager.getRingtone(applicationContext, alarmUri)
            }
            sirenRingtone?.let {
                if (!it.isPlaying) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        it.isLooping = true
                    }
                    it.play()
                }
            }
        } catch (_: Exception) {}
    }

    private fun stopSiren() {
        try {
            sirenRingtone?.let {
                if (it.isPlaying) {
                    it.stop()
                }
            }
        } catch (_: Exception) {}
    }

    private fun vibrateAlert() {
        try {
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            if (vibrator != null && vibrator.hasVibrator()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator.vibrate(
                        VibrationEffect.createWaveform(
                            longArrayOf(0, 500, 200, 500, 200, 1000),
                            -1
                        )
                    )
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(longArrayOf(0, 500, 200, 500, 200, 1000), -1)
                }
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        stopSiren()
        super.onDestroy()
    }
}
