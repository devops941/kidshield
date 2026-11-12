package com.kidshield.child.kidshield_child

import android.Manifest
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.location.Address
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import android.net.Uri
import android.os.PowerManager
import android.util.Base64
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar
import java.util.Locale
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val GPS_CHANNEL = "com.kidshield.child/gps"
    private val APPS_CHANNEL = "com.kidshield.child/apps"
    private val PERMISSIONS_CHANNEL = "com.kidshield.child/permissions"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Live GPS MethodChannel
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
                "startBackgroundLocationService" -> {
                    val childId = call.argument<String>("childId") ?: ""
                    val baseUrl = call.argument<String>("baseUrl") ?: "https://kidshield-1jvi.onrender.com/api"
                    try {
                        val intent = Intent(this, LocationForegroundService::class.java).apply {
                            action = LocationForegroundService.ACTION_START
                            putExtra(LocationForegroundService.EXTRA_CHILD_ID, childId)
                            putExtra(LocationForegroundService.EXTRA_BASE_URL, baseUrl)
                        }
                        ContextCompat.startForegroundService(this, intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_START_ERROR", e.localizedMessage, null)
                    }
                }
                "stopBackgroundLocationService" -> {
                    try {
                        val intent = Intent(this, LocationForegroundService::class.java).apply {
                            action = LocationForegroundService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_STOP_ERROR", e.localizedMessage, null)
                    }
                }
                "isBackgroundLocationServiceRunning" -> {
                    result.success(LocationForegroundService.isServiceRunning)
                }
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
                else -> result.notImplemented()
            }
        }

        // 2. Real Installed Apps & App Usage MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsagePermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    })
                    result.success(true)
                }
                "getInstalledApps" -> {
                    fetchInstalledApps(result)
                }
                "getRealAppUsage" -> {
                    fetchRealAppUsage(result)
                }
                "getBatteryLevel" -> {
                    result.success(getBatteryPercentage())
                }
                "getDeviceModel" -> {
                    val manufacturer = Build.MANUFACTURER?.replaceFirstChar { it.uppercase() } ?: ""
                    val model = Build.MODEL ?: ""
                    val devName = if (model.startsWith(manufacturer, ignoreCase = true)) model else "$manufacturer $model"
                    result.success(devName.trim())
                }
                else -> result.notImplemented()
            }
        }

        // 3. Android System Permissions & Settings Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAllPermissions" -> {
                    val fine = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    val coarse = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    val locGranted = fine || coarse

                    val bgGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED
                    } else {
                        locGranted
                    }

                    val usageGranted = hasUsageStatsPermission()

                    val notifGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ActivityCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                    } else {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                        nm.areNotificationsEnabled()
                    }

                    val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                    val batteryIgnored = powerManager.isIgnoringBatteryOptimizations(packageName)

                    val map = HashMap<String, Any>()
                    map["location"] = locGranted
                    map["backgroundLocation"] = bgGranted
                    map["usage"] = usageGranted
                    map["notification"] = notifGranted
                    map["batteryOptimization"] = batteryIgnored
                    result.success(map)
                }
                "requestLocationPermission" -> {
                    val fine = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    val coarse = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    if (!fine && !coarse) {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                            1001
                        )
                        result.success(true)
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val bg = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED
                        if (!bg) {
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                                1002
                            )
                        }
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                }
                "requestUsagePermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("USAGE_SETTINGS_ERROR", e.localizedMessage, null)
                    }
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            1003
                        )
                        result.success(true)
                    } else {
                        try {
                            val intent = Intent().apply {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                    action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                } else {
                                    action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                                    data = Uri.parse("package:$packageName")
                                }
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("NOTIF_SETTINGS_ERROR", e.localizedMessage, null)
                        }
                    }
                }
                "requestBatteryOptimization" -> {
                    try {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                        }
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("BATTERY_SETTINGS_ERROR", e.localizedMessage, null)
                        }
                    }
                }
                "openAppSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("APP_SETTINGS_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // ==========================================
    // GPS IMPLEMENTATION
    // ==========================================
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

    // ==========================================
    // APPS & USAGE STATS IMPLEMENTATION
    // ==========================================
    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
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
                    if (pkgName == packageName) continue // Skip KidShield child itself

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
                    result.error("APPS_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun fetchRealAppUsage(result: MethodChannel.Result) {
        executor.execute {
            try {
                if (!hasUsageStatsPermission()) {
                    mainHandler.post {
                        result.error("PERMISSION_REQUIRED", "Usage stats permission required", null)
                    }
                    return@execute
                }

                val report = ScreenTimeTracker.computeScreenTimeReport(this)
                if (report == null) {
                    mainHandler.post {
                        result.error("USAGE_ERROR", "Failed to compute daily screen time", null)
                    }
                    return@execute
                }

                val response = HashMap<String, Any>().apply {
                    put("date", report.date)
                    put("timezone", report.timezone)
                    put("totalMinutesToday", report.totalMinutesToday)
                    put("totalMinutesWeekly", report.totalMinutesWeekly)
                    put("totalMinutesMonthly", report.totalMinutesMonthly)
                    put("todayApps", report.todayApps)
                    put("weeklyApps", report.weeklyApps)
                    put("monthlyApps", report.monthlyApps)
                    put("apps", report.todayApps)
                    put("hourlyBreakdown", report.hourlyBreakdown)
                    put("batteryLevel", getBatteryPercentage())
                }

                mainHandler.post {
                    result.success(response)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("USAGE_ERROR", e.localizedMessage, null)
                }
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
            bitmap.compress(Bitmap.CompressFormat.PNG, 85, outputStream)
            Base64.encodeToString(outputStream.toByteArray(), Base64.NO_WRAP)
        } catch (_: Exception) {
            ""
        }
    }

    private fun getCategoryForPackage(pkg: String): String {
        val p = pkg.lowercase(Locale.US)
        return when {
            p.contains("youtube") || p.contains("netflix") || p.contains("prime") || p.contains("hotstar") -> "Entertainment"
            p.contains("whatsapp") || p.contains("instagram") || p.contains("facebook") || p.contains("twitter") || p.contains("telegram") -> "Social"
            p.contains("chrome") || p.contains("browser") || p.contains("firefox") || p.contains("opera") -> "Browsing"
            p.contains("game") || p.contains("pubg") || p.contains("freefire") || p.contains("roblox") || p.contains("minecraft") -> "Games"
            else -> "Education & Utility"
        }
    }
}
