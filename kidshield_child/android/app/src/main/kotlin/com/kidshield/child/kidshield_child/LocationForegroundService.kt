package com.kidshield.child.kidshield_child

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Address
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import java.util.concurrent.Executors

class LocationForegroundService : Service(), LocationListener {

    companion object {
        const val TAG = "KidShieldLocationFGS"
        const val CHANNEL_ID = "kidshield_location_channel"
        const val NOTIFICATION_ID = 2026
        const val ACTION_START = "ACTION_START_LOCATION_SERVICE"
        const val ACTION_STOP = "ACTION_STOP_LOCATION_SERVICE"
        const val EXTRA_CHILD_ID = "EXTRA_CHILD_ID"
        const val EXTRA_BASE_URL = "EXTRA_BASE_URL"

        const val PREFS_NAME = "FlutterSharedPreferences"
        const val PREF_SAVED_CHILD_ID = "flutter.saved_child_id"

        @Volatile
        var isServiceRunning = false
            private set
    }

    private var childId: String = ""
    private var baseUrl: String = "https://kidshield-1jvi.onrender.com/api"

    private lateinit var locationManager: LocationManager
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var lastUploadedLocation: Location? = null
    private var lastUploadTimestamp: Long = 0
    private var screenTimeTickCounter = 0

    // Real-Time App Lock Watchdog
    private val appLockHandler = Handler(Looper.getMainLooper())
    private var lastBlockedPkgShown: String? = null
    private var lastBlockedPkgTime = 0L

    private val appLockWatchdogRunnable = object : Runnable {
        override fun run() {
            checkForegroundAppAndEnforceLock()
            appLockHandler.postDelayed(this, 350L) // Real-time 350ms watchdog
        }
    }

    // Periodic sync runnable ensures updates every 15 seconds even when device is stationary
    private val periodicSyncRunnable = object : Runnable {
        override fun run() {
            queryAndUploadCurrentLocation()

            // Periodic restrictions sync from parent console every 15 seconds
            AppBlockManager.syncRestrictions(applicationContext, childId, baseUrl)

            // Real-time schedule boundary check (Study Mode / Bedtime alerts)
            AppBlockManager.checkScheduleAndNotify(applicationContext)

            // Periodic screen time background synchronization
            executor.execute {
                ScreenTimeTracker.syncUsageInBackground(applicationContext, childId, baseUrl)
            }

            mainHandler.postDelayed(this, 15000L) // Every 15 seconds
        }
    }

    // Hardware Power Button Emergency SOS Detection
    private val powerPressTimestamps = mutableListOf<Long>()
    private val POWER_PRESS_THRESHOLD_MS = 3500L // 3.5 seconds window
    private val REQUIRED_PRESS_COUNT = 4 // 4 clicks (screen toggles)
    private var lastSosTriggerTime = 0L

    private val screenPowerReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action
            if (action == Intent.ACTION_SCREEN_ON || action == Intent.ACTION_SCREEN_OFF) {
                val now = System.currentTimeMillis()
                // Prevent duplicate trigger bursts within 30 seconds
                if (now - lastSosTriggerTime < 30000L) {
                    return
                }

                // Discard older clicks beyond window
                powerPressTimestamps.removeAll { now - it > POWER_PRESS_THRESHOLD_MS }
                powerPressTimestamps.add(now)

                Log.d(TAG, "Hardware power button click detected: count=${powerPressTimestamps.size}")

                if (powerPressTimestamps.size >= REQUIRED_PRESS_COUNT) {
                    powerPressTimestamps.clear()
                    lastSosTriggerTime = now
                    Log.w(TAG, "🚨 [KidShield SOS] Hardware Power Button SOS trigger initiated!")
                    triggerHardwareEmergencySos()
                }
            }
        }
    }

    // Real-time App Installation Receiver
    private val appInstallReceiver = AppInstallReceiver()

    override fun onCreate() {
        super.onCreate()
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        createNotificationChannel()

        // Initialize local app block cache
        try {
            AppBlockManager.init(applicationContext)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize AppBlockManager: ${e.message}")
        }

        // Register hardware power button listener
        try {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            }
            registerReceiver(screenPowerReceiver, filter)
            Log.i(TAG, "Hardware SOS power button receiver registered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register screenPowerReceiver: ${e.message}")
        }

        // Register real-time new app installation listener
        try {
            val installFilter = IntentFilter(Intent.ACTION_PACKAGE_ADDED).apply {
                addDataScheme("package")
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(appInstallReceiver, installFilter, Context.RECEIVER_EXPORTED)
            } else {
                registerReceiver(appInstallReceiver, installFilter)
            }
            Log.i(TAG, "AppInstallReceiver dynamically registered in LocationForegroundService")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register appInstallReceiver: ${e.message}")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START

        if (action == ACTION_STOP) {
            stopTracking()
            stopSelf()
            return START_NOT_STICKY
        }

        // Extract childId and baseUrl
        val intentChildId = intent?.getStringExtra(EXTRA_CHILD_ID)
        val intentBaseUrl = intent?.getStringExtra(EXTRA_BASE_URL)

        if (!intentChildId.isNullOrEmpty()) {
            childId = intentChildId
        } else {
            // Fallback: Read from Flutter shared_preferences
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            childId = prefs.getString(PREF_SAVED_CHILD_ID, "") ?: ""
        }

        if (!intentBaseUrl.isNullOrEmpty()) {
            baseUrl = intentBaseUrl
        }

        startForegroundWithNotification()
        startTracking()

        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "KidShield Live Safety Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows persistent status while KidShield Junior is actively protecting this device"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun startForegroundWithNotification() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("KidShield Protection Active")
            .setContentText("Child device safety and live location monitoring active")
            .setSmallIcon(applicationInfo.icon)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            isServiceRunning = true
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground service: ${e.message}", e)
        }
    }

    private fun startTracking() {
        val fineGranted = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

        if (!fineGranted && !coarseGranted) {
            Log.w(TAG, "Location permissions not granted for background service")
            return
        }

        try {
            // 1. Continuous location updates from GPS & Network
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    25000L, // 25 seconds
                    5.0f,   // 5 meters
                    this,
                    Looper.getMainLooper()
                )
            }

            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    30000L,
                    10.0f,
                    this,
                    Looper.getMainLooper()
                )
            }

            // 2. Start fallback periodic sync
            mainHandler.removeCallbacks(periodicSyncRunnable)
            mainHandler.post(periodicSyncRunnable)

            // 3. Start real-time app lock enforcer watchdog
            appLockHandler.removeCallbacks(appLockWatchdogRunnable)
            appLockHandler.post(appLockWatchdogRunnable)

            // 4. Initial app restrictions sync
            AppBlockManager.syncRestrictions(applicationContext, childId, baseUrl)

            Log.i(TAG, "Location tracking and AppLock watchdog registered successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error registering location updates: ${e.message}")
        }
    }

    private fun stopTracking() {
        isServiceRunning = false
        try {
            locationManager.removeUpdates(this)
        } catch (_: Exception) {}
        mainHandler.removeCallbacks(periodicSyncRunnable)
        appLockHandler.removeCallbacks(appLockWatchdogRunnable)
    }

    // ==========================================
    // LocationListener Callbacks
    // ==========================================
    override fun onLocationChanged(location: Location) {
        val now = System.currentTimeMillis()
        // Deduplicate updates within 15 seconds unless moved more than 20 meters
        val last = lastUploadedLocation
        if (last != null && (now - lastUploadTimestamp < 15000L) && location.distanceTo(last) < 20.0f) {
            return
        }
        uploadLocation(location)
    }

    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}
    @Deprecated("Deprecated in Java")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}

    // ==========================================
    // Real-Time Foreground App Lock Enforcement
    // ==========================================
    private fun checkForegroundAppAndEnforceLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            if (powerManager != null && !powerManager.isInteractive) {
                return // Device screen off, idle sleep
            }

            if (!ScreenTimeTracker.hasUsageStatsPermission(applicationContext)) {
                return
            }

            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return
            val now = System.currentTimeMillis()
            val events = usm.queryEvents(now - 2500L, now)
            val event = UsageEvents.Event()
            var currentForegroundPackage: String? = null

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                    @Suppress("DEPRECATION")
                    event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    currentForegroundPackage = event.packageName
                }
            }

            if (currentForegroundPackage == null) {
                // Fallback check
                val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 3500L, now)
                if (!stats.isNullOrEmpty()) {
                    val recent = stats.maxByOrNull { it.lastTimeUsed }
                    if (recent != null && now - recent.lastTimeUsed < 3000L) {
                        currentForegroundPackage = recent.packageName
                    }
                }
            }

            if (!currentForegroundPackage.isNullOrEmpty()) {
                // If package is blocked and not KidShield itself
                if (currentForegroundPackage != packageName && AppBlockManager.isBlocked(applicationContext, currentForegroundPackage)) {
                    val isRecentDuplicate = (currentForegroundPackage == lastBlockedPkgShown) && (now - lastBlockedPkgTime < 800L)
                    if (!isRecentDuplicate) {
                        lastBlockedPkgShown = currentForegroundPackage
                        lastBlockedPkgTime = now
                        Log.w(TAG, "🚨 [KidShield App Lock] Blocked app launched in foreground: $currentForegroundPackage! Enforcing lock screen.")
                        AppBlockManager.launchBlockScreen(applicationContext, currentForegroundPackage)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in checkForegroundAppAndEnforceLock: ${e.message}")
        }
    }

    // ==========================================
    // Periodic / On-Demand Location Upload
    // ==========================================
    private fun queryAndUploadCurrentLocation() {
        val fineGranted = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!fineGranted && !coarseGranted) return

        try {
            var bestLoc: Location? = null

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && locationManager.allProviders.contains(LocationManager.FUSED_PROVIDER)) {
                try {
                    val fused = locationManager.getLastKnownLocation(LocationManager.FUSED_PROVIDER)
                    if (fused != null) bestLoc = fused
                } catch (_: Exception) {}
            }

            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                try {
                    val gps = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                    if (gps != null && (bestLoc == null || gps.time > bestLoc.time)) {
                        bestLoc = gps
                    }
                } catch (_: Exception) {}
            }

            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                try {
                    val net = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
                    if (net != null && (bestLoc == null || net.time > bestLoc.time)) {
                        bestLoc = net
                    }
                } catch (_: Exception) {}
            }

            if (bestLoc != null) {
                uploadLocation(bestLoc)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error querying current location: ${e.message}")
        }
    }

    private fun uploadLocation(location: Location) {
        if (childId.isEmpty()) {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            childId = prefs.getString(PREF_SAVED_CHILD_ID, "") ?: ""
            if (childId.isEmpty()) {
                Log.w(TAG, "Cannot upload location: ChildId is empty")
                return
            }
        }

        lastUploadedLocation = location
        lastUploadTimestamp = System.currentTimeMillis()

        executor.execute {
            try {
                // Reverse-geocode address
                var addressText = "GPS: ${String.format(Locale.US, "%.4f", location.latitude)}, ${String.format(Locale.US, "%.4f", location.longitude)}"
                try {
                    if (Geocoder.isPresent()) {
                        val geocoder = Geocoder(this, Locale.getDefault())
                        val addresses: List<Address>? = geocoder.getFromLocation(location.latitude, location.longitude, 1)
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
                } catch (_: Exception) {}

                val batteryLevel = getBatteryPercentage()

                // Construct JSON payload matching POST /api/locations
                val payload = JSONObject().apply {
                    put("childId", childId)
                    put("latitude", location.latitude)
                    put("longitude", location.longitude)
                    put("address", addressText)
                    put("accuracy", location.accuracy.toDouble())
                    put("speed", location.speed.toDouble())
                    put("batteryLevel", batteryLevel)
                    put("isOffline", false)
                }

                val endpoint = URL("$baseUrl/locations")
                val conn = (endpoint.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    connectTimeout = 12000
                    readTimeout = 12000
                    doOutput = true
                    setRequestProperty("Content-Type", "application/json")
                    setRequestProperty("Accept", "application/json")
                }

                OutputStreamWriter(conn.outputStream).use { writer ->
                    writer.write(payload.toString())
                    writer.flush()
                }

                val code = conn.responseCode
                Log.i(TAG, "Location uploaded to backend [$code]: (${location.latitude}, ${location.longitude})")
                conn.disconnect()
            } catch (e: Exception) {
                Log.e(TAG, "Network error uploading background location: ${e.message}")
            }
        }
    }

    private fun getBatteryPercentage(): Int {
        return try {
            val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } catch (_: Exception) {
            85
        }
    }

    private fun triggerHardwareEmergencySos() {
        // 1. Silent tactile feedback vibration so child knows distress signal was sent
        try {
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            if (vibrator != null && vibrator.hasVibrator()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator.vibrate(
                        VibrationEffect.createWaveform(
                            longArrayOf(0, 200, 100, 200, 100, 600),
                            -1
                        )
                    )
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(longArrayOf(0, 200, 100, 200, 100, 600), -1)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Vibration failed: ${e.message}")
        }

        // 2. Transmit SOS in background thread
        executor.execute {
            try {
                if (childId.isEmpty()) {
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    childId = prefs.getString(PREF_SAVED_CHILD_ID, "") ?: ""
                }
                if (childId.isEmpty()) {
                    Log.e(TAG, "Cannot trigger SOS: ChildId is empty")
                    return@execute
                }

                var lat = lastUploadedLocation?.latitude ?: 0.0
                var lng = lastUploadedLocation?.longitude ?: 0.0
                var addressText = "Emergency GPS Location"

                val fineGranted = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                val coarseGranted = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

                if (fineGranted || coarseGranted) {
                    try {
                        val gpsLoc = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                            ?: locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
                        if (gpsLoc != null) {
                            lat = gpsLoc.latitude
                            lng = gpsLoc.longitude
                        }
                    } catch (_: Exception) {}
                }

                if (lat != 0.0 && lng != 0.0) {
                    try {
                        if (Geocoder.isPresent()) {
                            val geocoder = Geocoder(this, Locale.getDefault())
                            val addresses = geocoder.getFromLocation(lat, lng, 1)
                            if (!addresses.isNullOrEmpty()) {
                                val a = addresses[0]
                                val items = mutableListOf<String>()
                                if (!a.subLocality.isNullOrBlank()) items.add(a.subLocality)
                                if (!a.locality.isNullOrBlank()) items.add(a.locality)
                                if (!a.adminArea.isNullOrBlank()) items.add(a.adminArea)
                                if (items.isNotEmpty()) addressText = items.joinToString(", ")
                                else if (!a.getAddressLine(0).isNullOrBlank()) addressText = a.getAddressLine(0)
                            }
                        }
                    } catch (_: Exception) {}
                }

                val batteryLevel = getBatteryPercentage()

                val payload = JSONObject().apply {
                    put("childId", childId)
                    put("latitude", lat)
                    put("longitude", lng)
                    put("address", addressText)
                    put("batteryLevel", batteryLevel)
                }

                val endpoint = URL("$baseUrl/sos/trigger")
                val conn = (endpoint.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    connectTimeout = 15000
                    readTimeout = 15000
                    doOutput = true
                    setRequestProperty("Content-Type", "application/json")
                    setRequestProperty("Accept", "application/json")
                }

                OutputStreamWriter(conn.outputStream).use { writer ->
                    writer.write(payload.toString())
                    writer.flush()
                }

                val code = conn.responseCode
                Log.i(TAG, "🚨 Hardware Emergency SOS sent to backend successfully [HTTP $code]")
                conn.disconnect()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send hardware SOS to backend: ${e.message}", e)
            }
        }
    }

    override fun onDestroy() {
        stopTracking()
        try {
            unregisterReceiver(screenPowerReceiver)
        } catch (_: Exception) {}
        try {
            unregisterReceiver(appInstallReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
