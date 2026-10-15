package com.humam.humam_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

/**
 * خدمة عداد الذكر والتسبيح العائم فوق التطبيقات بنظام أندرويد.
 * تتيح للمستخدم التسبيح والذكر أثناء تصفح التطبيقات الأخرى.
 */
class FloatingDhikrService : Service() {

    companion object {
        const val CHANNEL_ID = "floating_dhikr_channel"
        const val NOTIFICATION_ID = 20261
        const val ACTION_STOP = "com.humam.humam_app.STOP_FLOATING_DHIKR"

        var isRunning = false
            private set

        val DHIKR_PRESETS = listOf(
            "سُبْحَانَ اللهِ وَبِحَمْدِهِ",
            "أَسْتَغْفِرُ اللهَ وَأَتُوبُ إِلَيْهِ",
            "الْحَمْدُ لِلَّهِ",
            "لَا إِلَهَ إِلَّا اللهُ",
            "اللهُ أَكْبَرُ",
            "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ",
            "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ",
            "سُبْحَانَ اللهِ الْعَظِيمِ"
        )
    }

    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var dhikrIndex = 0
    private var count = 0

    private lateinit var dhikrTextView: TextView
    private lateinit var counterBtn: TextView
    private lateinit var indexIndicator: TextView

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createNotificationChannel()
        startForegroundServiceWithNotification()
        createFloatingView()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        val requestedDhikr = intent?.getStringExtra("dhikr_text")
        if (!requestedDhikr.isNullOrEmpty()) {
            val idx = DHIKR_PRESETS.indexOf(requestedDhikr)
            dhikrIndex = if (idx >= 0) idx else 0
            updateDhikrDisplay()
        }

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        floatingView?.let {
            try {
                windowManager?.removeView(it)
            } catch (e: Exception) {
                // View already detached
            }
        }
        floatingView = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "الذكر والتسبيح العائم",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "إشعار استمرار خدمة عداد الذكر العائم فوق التطبيقات"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun startForegroundServiceWithNotification() {
        val stopIntent = Intent(this, FloatingDhikrService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val appIntent = packageManager.getLaunchIntentForPackage(packageName)
        val appPendingIntent = PendingIntent.getActivity(
            this,
            0,
            appIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("الذكر العائم نشط")
            .setContentText("اضغط على العداد على الشاشة للتسبيح")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(appPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "إغلاق العداد", stopPendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (Build.VERSION.SDK_INT >= 34) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun createFloatingView() {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val dpToPx = { dp: Int ->
            TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP,
                dp.toFloat(),
                resources.displayMetrics
            ).toInt()
        }

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            dpToPx(210),
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = dpToPx(30)
            y = dpToPx(160)
        }

        // الحاوية الأساسية
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(12), dpToPx(10), dpToPx(12), dpToPx(12))

            // خلفية أنيقة بزوايا دائرية وإطار ذهبي عاجي
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#EE1F252E")) // كحلي/فحمي فخم شبه شفاف
                cornerRadius = dpToPx(20).toFloat()
                setStroke(dpToPx(1), Color.parseColor("#C5A059")) // إطار ذهبي
            }
            elevation = dpToPx(8).toFloat()
        }

        // شريط الرأس: مقبض السحب + زر الذكر السابق والتالي + زر الإغلاق
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        val dragIcon = TextView(this).apply {
            text = "✥"
            setTextColor(Color.parseColor("#A0AEC0"))
            textSize = 15f
            setPadding(dpToPx(4), dpToPx(2), dpToPx(8), dpToPx(2))
        }

        val prevBtn = TextView(this).apply {
            text = "◀"
            setTextColor(Color.parseColor("#C5A059"))
            textSize = 15f
            setPadding(dpToPx(6), dpToPx(2), dpToPx(6), dpToPx(2))
            setOnClickListener {
                dhikrIndex = if (dhikrIndex > 0) dhikrIndex - 1 else DHIKR_PRESETS.size - 1
                updateDhikrDisplay()
            }
        }

        indexIndicator = TextView(this).apply {
            text = "${dhikrIndex + 1}/${DHIKR_PRESETS.size}"
            setTextColor(Color.parseColor("#CBD5E0"))
            textSize = 10.5f
            setPadding(dpToPx(2), dpToPx(2), dpToPx(2), dpToPx(2))
        }

        val nextBtn = TextView(this).apply {
            text = "▶"
            setTextColor(Color.parseColor("#C5A059"))
            textSize = 15f
            setPadding(dpToPx(6), dpToPx(2), dpToPx(6), dpToPx(2))
            setOnClickListener {
                dhikrIndex = (dhikrIndex + 1) % DHIKR_PRESETS.size
                updateDhikrDisplay()
            }
        }

        val closeBtn = TextView(this).apply {
            text = "✕"
            setTextColor(Color.parseColor("#FEB2B2"))
            textSize = 15f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(dpToPx(8), dpToPx(2), dpToPx(4), dpToPx(2))
            setOnClickListener {
                stopSelf()
            }
        }

        header.addView(dragIcon)
        header.addView(prevBtn)
        header.addView(indexIndicator)
        header.addView(nextBtn)

        val spacer = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, 0, 1.0f)
        }
        header.addView(spacer)
        header.addView(closeBtn)
        root.addView(header)

        // نص الذكر الحالي
        dhikrTextView = TextView(this).apply {
            text = DHIKR_PRESETS[dhikrIndex]
            setTextColor(Color.WHITE)
            textSize = 13.5f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(dpToPx(4), dpToPx(8), dpToPx(4), dpToPx(8))
        }
        root.addView(dhikrTextView)

        // حاوية زر العداد
        val counterBox = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
        }

        counterBtn = TextView(this).apply {
            text = "$count"
            setTextColor(Color.WHITE)
            textSize = 21f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER

            val size = dpToPx(56)
            layoutParams = LinearLayout.LayoutParams(size, size).apply {
                gravity = Gravity.CENTER
            }

            // خلفية دائرية للعداد بلون ذهبي فخم
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                colors = intArrayOf(Color.parseColor("#D4AF37"), Color.parseColor("#8C6D37"))
                gradientType = GradientDrawable.LINEAR_GRADIENT
                orientation = GradientDrawable.Orientation.TL_BR
            }

            setOnClickListener {
                count++
                text = "$count"
                vibrate(28)
            }

            setOnLongClickListener {
                count = 0
                text = "0"
                vibrate(70)
                true
            }
        }
        counterBox.addView(counterBtn)

        val hintText = TextView(this).apply {
            text = "اضغط للزيادة • مطوّلاً للبدء من 0"
            setTextColor(Color.parseColor("#A0AEC0"))
            textSize = 8.5f
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(5), 0, 0)
        }
        counterBox.addView(hintText)

        root.addView(counterBox)

        // السحب والتحريك بحرية على الشاشة
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isMoving = false

        root.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isMoving = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    if (Math.abs(dx) > 5 || Math.abs(dy) > 5) {
                        isMoving = true
                    }
                    params.x = initialX + dx
                    params.y = initialY + dy
                    windowManager?.updateViewLayout(root, params)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    true
                }
                else -> false
            }
        }

        floatingView = root
        windowManager?.addView(floatingView, params)
    }

    private fun updateDhikrDisplay() {
        if (::dhikrTextView.isInitialized) {
            dhikrTextView.text = DHIKR_PRESETS[dhikrIndex]
        }
        if (::indexIndicator.isInitialized) {
            indexIndicator.text = "${dhikrIndex + 1}/${DHIKR_PRESETS.size}"
        }
    }

    @Suppress("DEPRECATION")
    private fun vibrate(milliseconds: Long) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator?.vibrate(
                    VibrationEffect.createOneShot(milliseconds, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else {
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(
                        VibrationEffect.createOneShot(milliseconds, VibrationEffect.DEFAULT_AMPLITUDE)
                    )
                } else {
                    vibrator?.vibrate(milliseconds)
                }
            }
        } catch (e: Exception) {
            // Ignore vibration error
        }
    }
}
