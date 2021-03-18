package com.example.personal_app

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterMain

class NotificationActivity : Service() {
    private val channel = "com.flutter.epic/epic"

    override fun onCreate() {
        super.onCreate()
        getMethodChannel(this).invokeMethod("kotlin", null)
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }

    private fun getMethodChannel(context: Context): MethodChannel {
        FlutterMain.startInitialization(context)
        FlutterMain.ensureInitializationComplete(context, arrayOfNulls(0))
        val engine = FlutterEngine(context.applicationContext)
        val entrypoint = DartExecutor.DartEntrypoint("lib/main.dart", "widget")
        engine.dartExecutor.executeDartEntrypoint(entrypoint)
        return MethodChannel(engine.dartExecutor.binaryMessenger, channel)
    }
}
