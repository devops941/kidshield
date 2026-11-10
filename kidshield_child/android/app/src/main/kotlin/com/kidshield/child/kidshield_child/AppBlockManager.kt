package com.kidshield.child.kidshield_child

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

object AppBlockManager {
    private const val TAG = "KidShieldAppBlockMgr"
    private const val PREFS_NAME = "KidShieldBlockPrefs"
    private const val PREF_BLOCKED_PACKAGES = "blocked_packages_json"
    private const val CHANNEL_BLOCK_ID = "kidshield_app_block_channel"
    private const val NOTIFICATION_BLOCK_ID = 2027

    private const val PREF_BEDTIME_START = "bedtime_start"
    private const val PREF_BEDTIME_END = "bedtime_end"
    private const val PREF_BEDTIME_ENABLED = "bedtime_enabled"
    private const val PREF_STUDY_START = "study_start"
    private const val PREF_STUDY_END = "study_end"
    private const val PREF_STUDY_ENABLED = "study_enabled"
    private const val PREF_WAS_STUDY_ACTIVE = "was_study_active"
    private const val PREF_WAS_BEDTIME_ACTIVE = "was_bedtime_active"

    private val blockedPackages = ConcurrentHashMap.newKeySet<String>()
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var isInitialized = false

    fun init(context: Context) {
        if (isInitialized) return
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val jsonStr = prefs.getString(PREF_BLOCKED_PACKAGES, null)
        if (!jsonStr.isNullOrEmpty()) {
            try {
                val array = JSONArray(jsonStr)
                for (i in 0 until array.length()) {
                    blockedPackages.add(array.getString(i))
                }
                Log.i(TAG, "Loaded ${blockedPackages.size} blocked packages from local cache")
            } catch (e: Exception) {
                Log.e(TAG, "Error loading blocked packages: ${e.message}")
            }
        }
        createBlockNotificationChannel(context)
        isInitialized = true
    }

    fun isBlocked(context: Context, packageName: String): Boolean {
        if (!isInitialized) init(context)
        return blockedPackages.contains(packageName)
    }

    fun getBlockedPackages(context: Context): Set<String> {
        if (!isInitialized) init(context)
        return HashSet(blockedPackages)
    }

    fun addBlockedPackage(context: Context, packageName: String) {
        if (!isInitialized) init(context)
        blockedPackages.add(packageName)
        saveToPrefs(context)
        Log.i(TAG, "Added blocked package locally: $packageName")
    }

    fun removeBlockedPackage(context: Context, packageName: String) {
        if (!isInitialized) init(context)
        blockedPackages.remove(packageName)
        saveToPrefs(context)
        Log.i(TAG, "Removed blocked package locally: $packageName")
    }

    fun updateBlockedPackages(context: Context, packages: Collection<String>) {
        if (!isInitialized) init(context)
        blockedPackages.clear()
        blockedPackages.addAll(packages)
        saveToPrefs(context)
        Log.i(TAG, "Updated blocked packages: ${blockedPackages.size} apps blocked")
    }

    private fun saveToPrefs(context: Context) {
        try {
            val array = JSONArray()
            for (pkg in blockedPackages) {
                array.put(pkg)
            }
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(PREF_BLOCKED_PACKAGES, array.toString())
                .apply()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to persist blocked packages: ${e.message}")
        }
    }

    private fun createBlockNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_BLOCK_ID,
                "KidShield App Security Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Shows parental control lock alerts when a restricted app is launched"
                setBypassDnd(true)
                setShowBadge(false)
            }
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            nm?.createNotificationChannel(channel)
        }
    }

    /**
     * Intercepts and displays the AppBlockActivity full screen, dismissing the blocked app
     */
    fun launchBlockScreen(context: Context, packageName: String) {
        try {
            // 1. Send Home intent to immediately kick the blocked app out of foreground
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(homeIntent)

            // 2. Launch the full-screen KidShield AppBlockActivity
            val blockIntent = Intent(context, AppBlockActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(AppBlockActivity.EXTRA_PACKAGE_NAME, packageName)
            }

            // Small delay so home intent minimizes target before block screen displays
            mainHandler.postDelayed({
                try {
                    context.startActivity(blockIntent)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start AppBlockActivity directly: ${e.message}")
                    // Fallback to Fullscreen Intent Notification for strict Android 10+ background limitations
                    launchViaFullScreenNotification(context, blockIntent, packageName)
                }
            }, 100L)
        } catch (e: Exception) {
            Log.e(TAG, "Failed in launchBlockScreen: ${e.message}", e)
        }
    }

    private fun launchViaFullScreenNotification(context: Context, targetIntent: Intent, packageName: String) {
        try {
            val pendingIntent = PendingIntent.getActivity(
                context,
                NOTIFICATION_BLOCK_ID,
                targetIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val pm = context.packageManager
            val appLabel = try {
                val appInfo = pm.getApplicationInfo(packageName, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (_: Exception) {
                packageName
            }

            val notification = NotificationCompat.Builder(context, CHANNEL_BLOCK_ID)
                .setSmallIcon(context.applicationInfo.icon)
                .setContentTitle("KidShield: $appLabel is Locked")
                .setContentText("Parent approval required before you can use this app.")
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setFullScreenIntent(pendingIntent, true)
                .setAutoCancel(true)
                .build()

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            nm?.notify(NOTIFICATION_BLOCK_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to trigger full screen notification: ${e.message}")
        }
    }

    /**
     * Polls the backend restrictions to sync parent approval status in real-time
     */
    fun syncRestrictions(
        context: Context,
        childIdParam: String?,
        baseUrlParam: String?,
        onComplete: ((isApproved: Boolean) -> Unit)? = null
    ) {
        val fPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val childId = if (!childIdParam.isNullOrEmpty()) childIdParam else fPrefs.getString("flutter.saved_child_id", "") ?: ""
        val savedBaseUrl = fPrefs.getString("flutter.custom_base_url", null)
        val baseUrl = if (!baseUrlParam.isNullOrEmpty()) {
            baseUrlParam
        } else if (!savedBaseUrl.isNullOrEmpty()) {
            savedBaseUrl
        } else {
            "http://192.168.1.9:5000/api"
        }

        if (childId.isEmpty()) {
            onComplete?.invoke(false)
            return
        }

        executor.execute {
            try {
                val endpoint = URL("${baseUrl.trimEnd('/')}/restrictions/$childId")
                val conn = (endpoint.openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"
                    connectTimeout = 8000
                    readTimeout = 8000
                    setRequestProperty("Accept", "application/json")
                }

                val code = conn.responseCode
                if (code == 200) {
                    val text = conn.inputStream.bufferedReader().use { it.readText() }
                    val json = JSONObject(text)
                    val restrictions = json.optJSONObject("restrictions")
                    if (restrictions != null) {
                        val blockedArr = restrictions.optJSONArray("blockedPackageNames")
                        val set = mutableSetOf<String>()
                        if (blockedArr != null) {
                            for (i in 0 until blockedArr.length()) {
                                set.add(blockedArr.getString(i))
                            }
                        }
                        updateBlockedPackages(context, set)

                        val bStart = restrictions.optString("bedtimeStart", "21:30")
                        val bEnd = restrictions.optString("bedtimeEnd", "06:30")
                        val bEnabled = restrictions.optBoolean("isBedtimeEnabled", true)

                        val sStart = restrictions.optString("studyTimeStart", "16:00")
                        val sEnd = restrictions.optString("studyTimeEnd", "18:00")
                        val sEnabled = restrictions.optBoolean("isStudyTimeEnabled", true)

                        updateSchedules(context, bStart, bEnd, bEnabled, sStart, sEnd, sEnabled)
                    }

                    // Check for unread parent notices (app approvals or rejections)
                    val noticesArr = json.optJSONArray("notices")
                    if (noticesArr != null && noticesArr.length() > 0) {
                        for (i in 0 until noticesArr.length()) {
                            val notice = noticesArr.optJSONObject(i) ?: continue
                            val id = notice.optString("_id")
                            val title = notice.optString("title", "Parent Notification")
                            val message = notice.optString("message", "")
                            val type = notice.optString("type")
                            showChildSystemNotification(context, id, title, message, type)
                            if (id.isNotEmpty()) {
                                markNoticeRead(baseUrl, id)
                            }
                        }
                    }

                    mainHandler.post {
                        onComplete?.invoke(true)
                    }
                    return@execute
                }
                conn.disconnect()
            } catch (e: Exception) {
                Log.w(TAG, "syncRestrictions error: ${e.message}")
            }
            mainHandler.post {
                onComplete?.invoke(false)
            }
        }
    }

    fun showChildSystemNotification(context: Context, id: String, title: String, message: String, type: String) {
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
            val channelId = "kidshield_parent_notices_channel"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    "Parent Safety Notices",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notices from parents regarding app approvals and restrictions"
                    enableLights(true)
                    enableVibration(true)
                }
                nm.createNotificationChannel(channel)
            }

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = if (launchIntent != null) {
                PendingIntent.getActivity(
                    context,
                    id.hashCode(),
                    launchIntent,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_UPDATE_CURRENT
                )
            } else null

            val notif = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(NotificationCompat.BigTextStyle().bigText(message))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .apply {
                    if (pendingIntent != null) setContentIntent(pendingIntent)
                }
                .build()

            nm.notify(id.hashCode(), notif)
            Log.i(TAG, "🔔 Displayed Parent Notice to child: $title - $message")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show child system notification: ${e.message}")
        }
    }

    fun updateSchedules(
        context: Context,
        bedtimeStart: String,
        bedtimeEnd: String,
        isBedtimeEnabled: Boolean,
        studyTimeStart: String,
        studyTimeEnd: String,
        isStudyTimeEnabled: Boolean
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(PREF_BEDTIME_START, bedtimeStart)
            .putString(PREF_BEDTIME_END, bedtimeEnd)
            .putBoolean(PREF_BEDTIME_ENABLED, isBedtimeEnabled)
            .putString(PREF_STUDY_START, studyTimeStart)
            .putString(PREF_STUDY_END, studyTimeEnd)
            .putBoolean(PREF_STUDY_ENABLED, isStudyTimeEnabled)
            .apply()
    }

    /**
     * Checks whether the current time matches Study Mode or Bedtime Mode boundaries.
     * Fires friendly notification alerts on transitions without spamming.
     */
    fun checkScheduleAndNotify(context: Context) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val bStart = prefs.getString(PREF_BEDTIME_START, "21:30") ?: "21:30"
            val bEnd = prefs.getString(PREF_BEDTIME_END, "06:30") ?: "06:30"
            val bEnabled = prefs.getBoolean(PREF_BEDTIME_ENABLED, true)

            val sStart = prefs.getString(PREF_STUDY_START, "16:00") ?: "16:00"
            val sEnd = prefs.getString(PREF_STUDY_END, "18:00") ?: "18:00"
            val sEnabled = prefs.getBoolean(PREF_STUDY_ENABLED, true)

            val cal = Calendar.getInstance(TimeZone.getTimeZone("Asia/Kolkata"))
            val currentMinutes = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)

            val isStudyActive = sEnabled && isTimeInRange(currentMinutes, toMinutes(sStart), toMinutes(sEnd))
            val isBedtimeActive = bEnabled && isTimeInRange(currentMinutes, toMinutes(bStart), toMinutes(bEnd))

            val wasStudyActive = prefs.getBoolean(PREF_WAS_STUDY_ACTIVE, false)
            val wasBedtimeActive = prefs.getBoolean(PREF_WAS_BEDTIME_ACTIVE, false)

            // Study Mode Transition Alerts
            if (!wasStudyActive && isStudyActive) {
                showScheduleNotification(
                    context,
                    "study_mode_start_alert",
                    "📚 Study & Homework Mode Started",
                    "Time to focus on your studies! Games & entertainment apps are paused until ${format12(sEnd)}."
                )
            } else if (wasStudyActive && !isStudyActive) {
                showScheduleNotification(
                    context,
                    "study_mode_end_alert",
                    "🎉 Study Time Finished!",
                    "Great job completing your study session! You can take a break now."
                )
            }

            // Bedtime Mode Transition Alerts
            if (!wasBedtimeActive && isBedtimeActive) {
                showScheduleNotification(
                    context,
                    "bedtime_mode_start_alert",
                    "🌙 Bedtime Mode Started",
                    "Time to sleep and rest well! Device access is restricted until ${format12(bEnd)}. Goodnight!"
                )
            } else if (wasBedtimeActive && !isBedtimeActive) {
                showScheduleNotification(
                    context,
                    "bedtime_mode_end_alert",
                    "☀️ Good Morning!",
                    "Bedtime mode has ended. Have a wonderful and productive day ahead!"
                )
            }

            prefs.edit()
                .putBoolean(PREF_WAS_STUDY_ACTIVE, isStudyActive)
                .putBoolean(PREF_WAS_BEDTIME_ACTIVE, isBedtimeActive)
                .apply()
        } catch (e: Exception) {
            Log.e(TAG, "checkScheduleAndNotify error: ${e.message}")
        }
    }

    private fun showScheduleNotification(context: Context, id: String, title: String, message: String) {
        showChildSystemNotification(context, id, title, message, "schedule_alert")
    }

    private fun toMinutes(timeStr: String): Int {
        return try {
            val parts = timeStr.trim().split(":")
            parts[0].toInt() * 60 + parts[1].toInt()
        } catch (_: Exception) {
            0
        }
    }

    private fun isTimeInRange(currentMinutes: Int, startMinutes: Int, endMinutes: Int): Boolean {
        return if (startMinutes <= endMinutes) {
            currentMinutes in startMinutes until endMinutes
        } else {
            currentMinutes >= startMinutes || currentMinutes < endMinutes
        }
    }

    private fun format12(timeStr: String): String {
        return try {
            val parts = timeStr.trim().split(":")
            var h = parts[0].toInt()
            val m = parts[1].toInt()
            val amPm = if (h >= 12) "PM" else "AM"
            h = h % 12
            if (h == 0) h = 12
            String.format(Locale.US, "%d:%02d %s", h, m, amPm)
        } catch (_: Exception) {
            timeStr
        }
    }
}

