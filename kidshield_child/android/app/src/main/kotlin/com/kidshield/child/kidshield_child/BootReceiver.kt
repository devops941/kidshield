package com.kidshield.child.kidshield_child

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "KidShieldBoot"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.i(TAG, "Received system broadcast action: $action")

        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isPaired = prefs.getBoolean("flutter.is_paired", false)
            val childId = prefs.getString("flutter.saved_child_id", "") ?: ""

            if (isPaired && childId.isNotEmpty()) {
                Log.i(TAG, "Child is paired ($childId). Auto-starting LocationForegroundService...")
                try {
                    val serviceIntent = Intent(context, LocationForegroundService::class.java).apply {
                        this.action = LocationForegroundService.ACTION_START
                        putExtra(LocationForegroundService.EXTRA_CHILD_ID, childId)
                        putExtra(LocationForegroundService.EXTRA_BASE_URL, "http://192.168.1.9:5000/api")
                    }
                    ContextCompat.startForegroundService(context, serviceIntent)
                    Log.i(TAG, "LocationForegroundService started successfully after boot.")

                    // Initial post-boot screen time tracking and synchronization
                    Thread {
                        ScreenTimeTracker.syncUsageInBackground(context, childId, "http://192.168.1.9:5000/api")
                    }.start()
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start LocationForegroundService on boot: ${e.message}", e)
                }
            } else {
                Log.w(TAG, "Child device not paired. Foreground service not started on boot.")
            }
        }
    }
}

