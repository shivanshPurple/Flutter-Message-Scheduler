package com.example.personal_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.telephony.SmsManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*


class MainActivity : FlutterActivity() {
    private val channel = "com.flutter.epic/epic"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, _ ->
                when (call.method) {
                    "notifyKotlin" -> {
                        val text = call.argument<String>("text")
                        val number = call.argument<String>("number")
                        val waIntent = Intent(Intent.ACTION_VIEW)
                        val url = "https://api.whatsapp.com/send?phone=$number&text=$text"
                        waIntent.setPackage("com.whatsapp")
                        waIntent.data = Uri.parse(url)
                        startActivity(waIntent)
                    }
                    "setAlarm" -> {
                        val hour = Integer.parseInt(call.argument("hour")!!)
                        val minutes = Integer.parseInt(call.argument("minutes")!!)

                        setAlarm(hour, minutes)
                    }
                    "sendSms" -> {
                        val text = call.argument<String>("text")
                        val number = call.argument<String>("number")
                        SmsManager.getDefault().sendTextMessage(number, null, text, null, null)
                    }
                }
            }
    }

    fun setAlarm(hour: Int, minutes: Int){
        val now = Calendar.getInstance()
        if (now[Calendar.HOUR_OF_DAY] >= hour) {
            now.add(Calendar.DATE, 1)
        }

        now[Calendar.HOUR_OF_DAY] = hour
        now[Calendar.MINUTE] = minutes
        now[Calendar.SECOND] = 0

        val intent = Intent(applicationContext, NotificationActivity::class.java)
        intent.addFlags(Intent.FLAG_RECEIVER_FOREGROUND)

        val pendingIntent = PendingIntent.getService(
            applicationContext,
            100,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT
        )

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setRepeating(
            AlarmManager.RTC_WAKEUP,
            now.timeInMillis,
            AlarmManager.INTERVAL_DAY,
            pendingIntent
        )
    }
}

class MyBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if ("android.intent.action.BOOT_COMPLETED" == intent.action) {
            val ma = MainActivity()
            ma.setAlarm(6,0)
        }
    }
}
