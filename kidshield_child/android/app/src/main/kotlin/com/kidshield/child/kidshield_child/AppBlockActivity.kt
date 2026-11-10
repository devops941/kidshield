package com.kidshield.child.kidshield_child

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

class AppBlockActivity : Activity() {

    companion object {
        const val EXTRA_PACKAGE_NAME = "EXTRA_PACKAGE_NAME"
    }

    private var targetPackage: String = ""
    private var targetAppName: String = "This App"
    private lateinit var statusPill: TextView
    private lateinit var checkButton: Button
    private lateinit var checkProgressBar: ProgressBar

    @SuppressLint("SetTextI18n")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Make activity display over lockscreen and keep screen responsive
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )

        targetPackage = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""

        val pm = packageManager
        var appIconDrawable = try {
            if (targetPackage.isNotEmpty()) pm.getApplicationIcon(targetPackage) else null
        } catch (_: Exception) { null }

        targetAppName = try {
            if (targetPackage.isNotEmpty()) {
                val info = pm.getApplicationInfo(targetPackage, 0)
                pm.getApplicationLabel(info).toString()
            } else "This App"
        } catch (_: Exception) {
            "This App"
        }

        val dp = resources.displayMetrics.density

        // Root container: Deep navy background
        val rootScrollView = ScrollView(this).apply {
            setBackgroundColor(Color.parseColor("#0B1120"))
            isFillViewport = true
        }

        val mainLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding((24 * dp).toInt(), (40 * dp).toInt(), (24 * dp).toInt(), (32 * dp).toInt())
        }

        // Top Shield Icon Badge
        val topBadge = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            val shape = GradientDrawable().apply {
                setColor(Color.parseColor("#1E293B"))
                setStroke((1.5 * dp).toInt(), Color.parseColor("#334155"))
                cornerRadius = 24 * dp
            }
            background = shape
            setPadding((16 * dp).toInt(), (8 * dp).toInt(), (16 * dp).toInt(), (8 * dp).toInt())
        }

        val shieldTitle = TextView(this).apply {
            text = "🛡️ KidShield Junior Security"
            setTextColor(Color.parseColor("#94A3B8"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
            typeface = Typeface.DEFAULT_BOLD
        }
        topBadge.addView(shieldTitle)
        mainLayout.addView(topBadge)

        // Spacer
        val spacer1 = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, (28 * dp).toInt())
        }
        mainLayout.addView(spacer1)

        // Central Card Container
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            val cardShape = GradientDrawable().apply {
                setColor(Color.parseColor("#0F172A"))
                setStroke((1.5 * dp).toInt(), Color.parseColor("#1E293B"))
                cornerRadius = 24 * dp
            }
            background = cardShape
            setPadding((24 * dp).toInt(), (28 * dp).toInt(), (24 * dp).toInt(), (28 * dp).toInt())
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        }

        // App Icon Container
        val iconContainer = LinearLayout(this).apply {
            gravity = Gravity.CENTER
            val iconShape = GradientDrawable().apply {
                setColor(Color.parseColor("#1E293B"))
                cornerRadius = 20 * dp
                setStroke((1 * dp).toInt(), Color.parseColor("#334155"))
            }
            background = iconShape
            val p = (12 * dp).toInt()
            setPadding(p, p, p, p)
            layoutParams = LinearLayout.LayoutParams((84 * dp).toInt(), (84 * dp).toInt())
        }

        val appIconView = ImageView(this).apply {
            if (appIconDrawable != null) {
                setImageDrawable(appIconDrawable)
            } else {
                setImageResource(android.R.drawable.ic_lock_lock)
            }
            scaleType = ImageView.ScaleType.FIT_CENTER
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT)
        }
        iconContainer.addView(appIconView)
        card.addView(iconContainer)

        // Spacer
        val spacerCard1 = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, (16 * dp).toInt())
        }
        card.addView(spacerCard1)

        // App Name
        val appNameView = TextView(this).apply {
            text = targetAppName
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        card.addView(appNameView)

        // Spacer
        val spacerCard2 = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, (8 * dp).toInt())
        }
        card.addView(spacerCard2)

        // Status Pill
        statusPill = TextView(this).apply {
            text = "⏳ Awaiting Parent Approval"
            setTextColor(Color.parseColor("#F59E0B"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.DEFAULT_BOLD
            val pillShape = GradientDrawable().apply {
                setColor(Color.parseColor("#26F59E0B"))
                cornerRadius = 16 * dp
                setStroke((1 * dp).toInt(), Color.parseColor("#F59E0B"))
            }
            background = pillShape
            setPadding((14 * dp).toInt(), (6 * dp).toInt(), (14 * dp).toInt(), (6 * dp).toInt())
            gravity = Gravity.CENTER
        }
        card.addView(statusPill)

        // Spacer
        val spacerCard3 = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, (20 * dp).toInt())
        }
        card.addView(spacerCard3)

        // English Instruction Text
        val instructionView = TextView(this).apply {
            text = "Your parent has received a notification about this app.\nFor your safety, you cannot open or use it until your parent grants permission in KidShield Parent."
            setTextColor(Color.parseColor("#94A3B8"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.25f)
        }
        card.addView(instructionView)

        // Spacer
        val spacerCard4 = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, (12 * dp).toInt())
        }
        card.addView(spacerCard4)

        // Tamil Translation
        val tamilInstructionView = TextView(this).apply {
            text = "பெற்றோர் KidShield செயலியின் மூலம் அனுமதி வழங்கும் வரை இந்த செயலியைப் பயன்படுத்த முடியாது."
            setTextColor(Color.parseColor("#64748B"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.2f)
        }
        card.addView(tamilInstructionView)

        mainLayout.addView(card)

        // Spacer
        val spacer2 = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, (28 * dp).toInt())
        }
        mainLayout.addView(spacer2)

        // Check Progress Bar (Initially Gone)
        checkProgressBar = ProgressBar(this).apply {
            visibility = View.GONE
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = (12 * dp).toInt()
            }
        }
        mainLayout.addView(checkProgressBar)

        // Button 1: Check If Parent Approved
        checkButton = Button(this).apply {
            text = "🔄 Check Approval Status"
            setTextColor(Color.parseColor("#38BDF8"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            typeface = Typeface.DEFAULT_BOLD
            val btnOutline = GradientDrawable().apply {
                setColor(Color.parseColor("#0F172A"))
                cornerRadius = 14 * dp
                setStroke((1.5 * dp).toInt(), Color.parseColor("#0284C7"))
            }
            background = btnOutline
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, (52 * dp).toInt()).apply {
                bottomMargin = (14 * dp).toInt()
            }
            setOnClickListener {
                verifyParentApprovalStatus()
            }
        }
        mainLayout.addView(checkButton)

        // Button 2: Return to Home Screen (Primary Coral / Blue)
        val homeButton = Button(this).apply {
            text = "← Return to Home Screen"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            typeface = Typeface.DEFAULT_BOLD
            val btnShape = GradientDrawable().apply {
                setColor(Color.parseColor("#2563EB"))
                cornerRadius = 14 * dp
            }
            background = btnShape
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, (52 * dp).toInt())
            setOnClickListener {
                goToHomeScreen()
            }
        }
        mainLayout.addView(homeButton)

        rootScrollView.addView(mainLayout)
        setContentView(rootScrollView)
    }

    private fun verifyParentApprovalStatus() {
        checkProgressBar.visibility = View.VISIBLE
        checkButton.isEnabled = false
        checkButton.text = "Checking with parent..."

        AppBlockManager.syncRestrictions(this, null, null) { success ->
            checkProgressBar.visibility = View.GONE
            checkButton.isEnabled = true
            checkButton.text = "🔄 Check Approval Status"

            val isStillBlocked = AppBlockManager.isBlocked(this, targetPackage)
            if (!isStillBlocked && targetPackage.isNotEmpty()) {
                // Parent approved!
                statusPill.text = "✅ Parent Approved!"
                statusPill.setTextColor(Color.parseColor("#10B981"))
                val pillShape = GradientDrawable().apply {
                    setColor(Color.parseColor("#2610B981"))
                    cornerRadius = 16 * resources.displayMetrics.density
                    setStroke((1 * resources.displayMetrics.density).toInt(), Color.parseColor("#10B981"))
                }
                statusPill.background = pillShape

                Toast.makeText(this, "Parent approved $targetAppName! Opening app...", Toast.LENGTH_LONG).show()

                // Launch approved app
                val launchIntent = packageManager.getLaunchIntentForPackage(targetPackage)
                if (launchIntent != null) {
                    launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(launchIntent)
                }
                finish()
            } else {
                Toast.makeText(this, "Not approved yet. Please ask your parent to approve.", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun goToHomeScreen() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Prevent bypassing lock screen via Back button
        goToHomeScreen()
    }
}

