package com.kidshield.child.kidshield_child

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Process
import android.util.Base64
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

object ScreenTimeTracker {

    private const val TAG = "KidShieldScreenTime"
    private const val PREFS_NAME = "KidShieldUsagePrefs"
    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"

    private const val PREF_LAST_DATE = "last_calculated_date"
    private const val PREF_LAST_TOTAL_MINUTES = "last_total_minutes"
    private const val PREF_LAST_PAYLOAD = "last_payload_json"
    private const val PREF_IS_SYNCED = "is_synced_to_backend"

    // Default reporting timezone is Asia/Kolkata (Indian Standard Time)
    val REPORTING_TIMEZONE: TimeZone = TimeZone.getTimeZone("Asia/Kolkata")

    // Irrelevant internal system components and launchers excluded from child leisure screen time
    private val EXCLUDED_SYSTEM_PACKAGES = hashSetOf(
        "android",
        "com.android.systemui",
        "com.google.android.gms",
        "com.google.android.googlequicksearchbox",
        "com.google.android.inputmethod.latin",
        "com.samsung.android.honeyboard",
        "com.sec.android.inputmethod",
        "com.google.android.permissioncontroller",
        "com.android.permissioncontroller",
        "com.sec.android.app.launcher", // Samsung One UI Home
        "com.google.android.apps.nexuslauncher", // Pixel Launcher
        "com.android.launcher",
        "com.android.launcher3",
        "com.mi.android.globallauncher",
        "com.miui.home",
        "com.oppo.launcher",
        "com.coloros.launcher",
        "com.vivo.launcher",
        "com.bbk.launcher2",
        "com.huawei.android.launcher",
        "com.oneplus.launcher",
        "com.teslacoilsw.launcher",
        "com.kidshield.parent.kidshield_parent",
        "com.kidshield.child.kidshield_child" // KidShield Junior itself is excluded from leisure screen time
    )

    fun isExcluded(pkg: String?, context: Context? = null): Boolean {
        if (pkg.isNullOrEmpty()) return true
        if (EXCLUDED_SYSTEM_PACKAGES.contains(pkg)) return true
        val lower = pkg.lowercase(Locale.US)
        if (lower.contains("launcher") || lower.contains("systemui") || lower.contains("honeyboard") || lower.contains("kidshield")) {
            return true
        }
        if (context != null) {
            try {
                val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
                val resolveInfo = context.packageManager.resolveActivity(homeIntent, PackageManager.MATCH_DEFAULT_ONLY)
                if (resolveInfo?.activityInfo?.packageName == pkg) {
                    return true
                }
            } catch (_: Exception) {}
        }
        return false
    }

    fun hasUsageStatsPermission(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Interval representing continuous app foreground activity
     */
    data class UsageInterval(val startTime: Long, val endTime: Long)

    /**
     * Represents the calculated daily screen time report
     */
    data class ScreenTimeReport(
        val date: String,
        val timezone: String,
        val totalMinutesToday: Int,
        val totalMinutesWeekly: Int,
        val totalMinutesMonthly: Int,
        val todayApps: List<Map<String, Any>>,
        val weeklyApps: List<Map<String, Any>>,
        val monthlyApps: List<Map<String, Any>>
    )

    /**
     * Calculates accurate daily screen time and per-app breakdowns with strict local midnight boundary.
     * Prevents double-counting overlapping or concurrent app usage by merging activity intervals.
     */
    fun computeScreenTimeReport(context: Context): ScreenTimeReport? {
        if (!hasUsageStatsPermission(context)) {
            Log.w(TAG, "Cannot compute screen time: UsageStats permission missing")
            return null
        }

        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
        if (usm == null) {
            Log.e(TAG, "UsageStatsManager service is null")
            return null
        }

        val now = System.currentTimeMillis()

        // 1. Strict Local Day Boundaries (Asia/Kolkata)
        val calToday = Calendar.getInstance(REPORTING_TIMEZONE).apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val todayStart = calToday.timeInMillis
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply { timeZone = REPORTING_TIMEZONE }
        val dateKey = dateFormat.format(calToday.time)

        // 2. Week Start (7 days ago midnight)
        val calWeek = Calendar.getInstance(REPORTING_TIMEZONE).apply {
            timeInMillis = now
            add(Calendar.DAY_OF_YEAR, -7)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val weekStart = calWeek.timeInMillis

        // 3. Month Start (30 days ago midnight)
        val calMonth = Calendar.getInstance(REPORTING_TIMEZONE).apply {
            timeInMillis = now
            add(Calendar.DAY_OF_YEAR, -30)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val monthStart = calMonth.timeInMillis

        // 4. Calculate Non-Overlapping Device Screen Time & Per-Package Time via UsageEvents
        val packageTodayTimeMap = HashMap<String, Long>()
        val packageLaunchCountMap = HashMap<String, Int>()
        val interactiveDeviceIntervals = ArrayList<UsageInterval>()

        try {
            val events = usm.queryEvents(todayStart, now)
            val event = UsageEvents.Event()

            // Track active sessions per package
            val packageOpenTime = HashMap<String, Long>()

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val pkg = event.packageName ?: continue
                if (isExcluded(pkg, context)) continue
                val time = event.timeStamp

                when (event.eventType) {
                    UsageEvents.Event.ACTIVITY_RESUMED,
                    @Suppress("DEPRECATION")
                    UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        packageOpenTime[pkg] = Math.max(time, todayStart)
                        packageLaunchCountMap[pkg] = (packageLaunchCountMap[pkg] ?: 0) + 1
                    }
                    UsageEvents.Event.ACTIVITY_PAUSED,
                    @Suppress("DEPRECATION")
                    UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                        val openTime = packageOpenTime.remove(pkg)
                        val start = openTime ?: todayStart // If resumed prior to midnight
                        val end = Math.min(time, now)
                        if (end > start) {
                            val duration = end - start
                            packageTodayTimeMap[pkg] = (packageTodayTimeMap[pkg] ?: 0L) + duration
                            interactiveDeviceIntervals.add(UsageInterval(start, end))
                        }
                    }
                }
            }

            // Close any currently active foreground sessions at 'now'
            for ((pkg, openTime) in packageOpenTime) {
                if (isExcluded(pkg, context)) continue
                val start = Math.max(openTime, todayStart)
                if (now > start) {
                    val duration = now - start
                    packageTodayTimeMap[pkg] = (packageTodayTimeMap[pkg] ?: 0L) + duration
                    interactiveDeviceIntervals.add(UsageInterval(start, now))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error querying UsageEvents: ${e.message}")
        }

        // 5. Merge Overlapping Interactive Intervals to Prevent Double Counting
        val mergedIntervals = mergeIntervals(interactiveDeviceIntervals)
        var totalInteractiveMillis = 0L
        for (interval in mergedIntervals) {
            totalInteractiveMillis += (interval.endTime - interval.startTime)
        }

        var totalMinutesToday = (totalInteractiveMillis / 60000L).toInt()

        // Fallback: If UsageEvents was empty or disabled on ROM, query aggregate stats with strict midnight cap
        val weeklyMap = HashMap<String, Long>()
        val monthlyMap = HashMap<String, Long>()

        val weeklyList = usm.queryUsageStats(UsageStatsManager.INTERVAL_WEEKLY, weekStart, now)
        if (weeklyList != null) {
            for (u in weeklyList) {
                weeklyMap[u.packageName] = (weeklyMap[u.packageName] ?: 0L) + u.totalTimeInForeground
            }
        }

        val monthlyList = usm.queryUsageStats(UsageStatsManager.INTERVAL_MONTHLY, monthStart, now)
        if (monthlyList != null) {
            for (u in monthlyList) {
                monthlyMap[u.packageName] = (monthlyMap[u.packageName] ?: 0L) + u.totalTimeInForeground
            }
        }

        // If today event tracking was empty, populate from daily aggregate
        if (packageTodayTimeMap.isEmpty()) {
            val todayList = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, todayStart, now)
            if (todayList != null) {
                for (u in todayList) {
                    packageTodayTimeMap[u.packageName] = (packageTodayTimeMap[u.packageName] ?: 0L) + u.totalTimeInForeground
                }
            }
            // Clamp total to elapsed minutes since midnight to avoid carrying over yesterday
            val elapsedMinutesSinceMidnight = ((now - todayStart) / 60000L).toInt()
            var sum = 0
            for ((pkg, ms) in packageTodayTimeMap) {
                if (!isExcluded(pkg, context)) {
                    sum += (ms / 60000L).toInt()
                }
            }
            totalMinutesToday = Math.min(sum, elapsedMinutesSinceMidnight)
        }

        // 6. Build App Usage Breakdowns
        val allPackages = HashSet<String>().apply {
            addAll(packageTodayTimeMap.keys)
            addAll(weeklyMap.keys)
            addAll(monthlyMap.keys)
        }

        val pm = context.packageManager
        val todayApps = ArrayList<Map<String, Any>>()
        val weeklyApps = ArrayList<Map<String, Any>>()
        val monthlyApps = ArrayList<Map<String, Any>>()

        var totalMinutesWeekly = 0
        var totalMinutesMonthly = 0

        for (pkg in allPackages) {
            // Exclude internal system processes and launchers from the visible apps breakdown
            if (isExcluded(pkg, context)) continue

            val tMs = packageTodayTimeMap[pkg] ?: 0L
            val wMs = weeklyMap[pkg] ?: 0L
            val mMs = monthlyMap[pkg] ?: 0L

            val todayMins = (tMs / 60000L).toInt()
            val weekMins = Math.max(todayMins, (wMs / 60000L).toInt())
            val monthMins = Math.max(weekMins, (mMs / 60000L).toInt())

            if (monthMins <= 0 && todayMins <= 0 && weekMins <= 0) continue

            totalMinutesWeekly += weekMins
            totalMinutesMonthly += monthMins

            var appName = pkg
            var iconBase64 = ""
            try {
                val appInfo = pm.getApplicationInfo(pkg, 0)
                appName = pm.getApplicationLabel(appInfo).toString()
                val icon = pm.getApplicationIcon(appInfo)
                iconBase64 = drawableToBase64(icon)
            } catch (_: Exception) {}

            val category = getCategoryForPackage(pkg, appName)
            val launchCount = packageLaunchCountMap[pkg] ?: 0

            val item = HashMap<String, Any>().apply {
                put("packageName", pkg)
                put("appName", appName)
                put("category", category)
                put("icon", iconBase64)
                put("usageMinutesToday", todayMins)
                put("usageMinutesWeekly", weekMins)
                put("usageMinutesMonthly", monthMins)
                put("launchCountToday", launchCount)
            }

            if (todayMins > 0) todayApps.add(item)
            if (weekMins > 0) weeklyApps.add(item)
            if (monthMins > 0) monthlyApps.add(item)
        }

        todayApps.sortByDescending { (it["usageMinutesToday"] as Int) }
        weeklyApps.sortByDescending { (it["usageMinutesWeekly"] as Int) }
        monthlyApps.sortByDescending { (it["usageMinutesMonthly"] as Int) }

        // Guarantee weekly and monthly are at least as large as today's actual usage
        totalMinutesWeekly = Math.max(totalMinutesWeekly, totalMinutesToday)
        totalMinutesMonthly = Math.max(totalMinutesMonthly, totalMinutesWeekly)

        val report = ScreenTimeReport(
            date = dateKey,
            timezone = "Asia/Kolkata",
            totalMinutesToday = totalMinutesToday,
            totalMinutesWeekly = totalMinutesWeekly,
            totalMinutesMonthly = totalMinutesMonthly,
            todayApps = todayApps,
            weeklyApps = weeklyApps,
            monthlyApps = monthlyApps
        )

        // Save locally for offline reliability
        persistReportLocally(context, report)

        return report
    }

    /**
     * Merges overlapping time intervals so that concurrent or background foreground services
     * do not double-count device active screen time.
     */
    private fun mergeIntervals(intervals: List<UsageInterval>): List<UsageInterval> {
        if (intervals.size <= 1) return intervals
        val sorted = intervals.sortedBy { it.startTime }
        val merged = ArrayList<UsageInterval>()

        var currentStart = sorted[0].startTime
        var currentEnd = sorted[0].endTime

        for (i in 1 until sorted.size) {
            val interval = sorted[i]
            if (interval.startTime <= currentEnd) {
                // Overlapping or contiguous interval -> extend boundary
                currentEnd = Math.max(currentEnd, interval.endTime)
            } else {
                merged.add(UsageInterval(currentStart, currentEnd))
                currentStart = interval.startTime
                currentEnd = interval.endTime
            }
        }
        merged.add(UsageInterval(currentStart, currentEnd))
        return merged
    }

    /**
     * Persists the computed screen time report locally so unsynced data is never lost offline.
     */
    private fun persistReportLocally(context: Context, report: ScreenTimeReport) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = JSONObject().apply {
                put("date", report.date)
                put("timezone", report.timezone)
                put("totalMinutesToday", report.totalMinutesToday)
                put("totalMinutesWeekly", report.totalMinutesWeekly)
                put("totalMinutesMonthly", report.totalMinutesMonthly)
                put("timestamp", System.currentTimeMillis())

                val appsArray = JSONArray()
                for (app in report.todayApps) {
                    val appJson = JSONObject().apply {
                        put("packageName", app["packageName"])
                        put("appName", app["appName"])
                        put("category", app["category"])
                        put("icon", app["icon"])
                        put("usageMinutesToday", app["usageMinutesToday"])
                        put("usageMinutesWeekly", app["usageMinutesWeekly"])
                        put("usageMinutesMonthly", app["usageMinutesMonthly"])
                        put("launchCountToday", app["launchCountToday"])
                    }
                    appsArray.put(appJson)
                }
                put("todayApps", appsArray)
            }

            prefs.edit()
                .putString(PREF_LAST_DATE, report.date)
                .putInt(PREF_LAST_TOTAL_MINUTES, report.totalMinutesToday)
                .putString(PREF_LAST_PAYLOAD, json.toString())
                .apply()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to persist report locally: ${e.message}")
        }
    }

    /**
     * Synchronizes the daily screen time report to the backend REST API.
     * Retries automatically if previously offline.
     */
    fun syncUsageInBackground(context: Context, childIdParam: String?, baseUrlParam: String?) {
        val childId = if (!childIdParam.isNullOrEmpty()) {
            childIdParam
        } else {
            val fPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            fPrefs.getString("flutter.saved_child_id", "") ?: ""
        }

        if (childId.isEmpty()) {
            Log.w(TAG, "Cannot sync usage: Child ID not found")
            return
        }

        val baseUrl = if (!baseUrlParam.isNullOrEmpty()) baseUrlParam else "http://192.168.1.9:5000/api"

        val report = computeScreenTimeReport(context) ?: return

        try {
            val appsArray = JSONArray()
            // Combine all active apps for sync
            val allAppsMap = HashMap<String, Map<String, Any>>()
            for (app in report.monthlyApps) allAppsMap[app["packageName"] as String] = app
            for (app in report.weeklyApps) allAppsMap[app["packageName"] as String] = app
            for (app in report.todayApps) allAppsMap[app["packageName"] as String] = app

            for ((_, app) in allAppsMap) {
                val appObj = JSONObject().apply {
                    put("packageName", app["packageName"])
                    put("appName", app["appName"])
                    put("category", app["category"])
                    put("icon", app["icon"])
                    put("usageMinutesToday", app["usageMinutesToday"])
                    put("usageMinutesWeekly", app["usageMinutesWeekly"])
                    put("usageMinutesMonthly", app["usageMinutesMonthly"])
                    put("launchCountToday", app["launchCountToday"])
                }
                appsArray.put(appObj)
            }

            val payload = JSONObject().apply {
                put("childId", childId)
                put("date", report.date)
                put("timezone", report.timezone)
                put("totalMinutesToday", report.totalMinutesToday)
                put("usageData", appsArray)
            }

            val endpoint = URL("$baseUrl/app-usage/sync")
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
            if (code == 200 || code == 201) {
                Log.i(TAG, "Daily Screen Time synced to backend [HTTP $code]: ${report.totalMinutesToday} mins on ${report.date}")
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().putBoolean(PREF_IS_SYNCED, true).apply()
            } else {
                Log.w(TAG, "Backend returned HTTP $code when syncing usage")
            }
            conn.disconnect()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to upload usage to backend (offline or server unreachable): ${e.message}")
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putBoolean(PREF_IS_SYNCED, false).apply()
        }
    }

    /**
     * Converts a Drawable into a compact Base64 PNG string
     */
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

    /**
     * Resolves appropriate category for application package name
     */
    private fun getCategoryForPackage(pkg: String, name: String): String {
        val p = pkg.lowercase(Locale.US)
        val n = name.lowercase(Locale.US)
        return when {
            p.contains("launcher") || p.contains("oneui") || p.contains("home") -> "System Launcher"
            p.contains("youtube") || p.contains("netflix") || p.contains("prime") || p.contains("hotstar") || p.contains("spotify") -> "Entertainment"
            p.contains("whatsapp") || p.contains("instagram") || p.contains("facebook") || p.contains("twitter") || p.contains("telegram") || p.contains("social") -> "Social"
            p.contains("chrome") || p.contains("browser") || p.contains("firefox") || p.contains("opera") -> "Browsing"
            p.contains("game") || p.contains("pubg") || p.contains("freefire") || p.contains("roblox") || p.contains("minecraft") || n.contains("game") -> "Games"
            p.contains("tutor") || p.contains("study") || p.contains("school") || p.contains("learn") || p.contains("byju") -> "Education"
            p.contains("camera") || p.contains("gallery") || p.contains("photo") -> "Photos & Media"
            else -> "Utility"
        }
    }
}

