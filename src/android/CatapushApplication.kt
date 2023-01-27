package com.catapush.cordova.sdk

import android.app.NotificationChannel
import android.app.NotificationManager
import android.graphics.Color
import android.os.Build
import androidx.multidex.MultiDexApplication
import com.catapush.cordova.sdk.example.MainActivity
import com.catapush.library.Catapush
import com.catapush.library.gms.CatapushGms
import com.catapush.library.interfaces.Callback
import com.catapush.library.interfaces.ICatapushInitializer
import com.catapush.library.notifications.NotificationTemplate
import org.apache.cordova.LOG
import java.util.*


class CatapushApplication : MultiDexApplication(), ICatapushInitializer {

  companion object {
    private lateinit var CHANNEL_ID: String
    private lateinit var CHANNEL_NAME: String
    private lateinit var NOTIFICATION_TITLE: String
    private var NOTIFICATION_ICON_RES_ID: Int = 0
    private var NOTIFICATION_COLOR: Int = Color.BLUE
  }

  override fun onCreate() {
    super.onCreate()
    initCatapush()
  }

  override fun initCatapush() {
    readCordovaConfig()

    val notificationTemplate = NotificationTemplate.Builder(CHANNEL_ID)
      .swipeToDismissEnabled(true)
      .vibrationEnabled(true)
      .vibrationPattern(longArrayOf(100, 200, 100, 300))
      .soundEnabled(true)
      .circleColor(NOTIFICATION_COLOR)
      .iconId(NOTIFICATION_ICON_RES_ID)
      .useAttachmentPreviewAsLargeIcon(true)
      .ledEnabled(true)
      .ledColor(NOTIFICATION_COLOR)
      .ledOnMS(2000)
      .ledOffMS(1000)
      .apply {
        if (NOTIFICATION_TITLE.isNotBlank())
          title(NOTIFICATION_TITLE)
      }
      .build()

    val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      var channel = nm.getNotificationChannel(notificationTemplate.notificationChannelId)
      val shouldCreateOrUpdate =
        channel == null || !CHANNEL_NAME.contentEquals(channel.name)
      if (shouldCreateOrUpdate) {
        if (channel == null) {
          channel = NotificationChannel(
            notificationTemplate.notificationChannelId,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
          )
          channel.enableVibration(notificationTemplate.isVibrationEnabled)
          channel.vibrationPattern = notificationTemplate.vibrationPattern
          channel.enableLights(notificationTemplate.isLedEnabled)
          channel.lightColor = notificationTemplate.ledColor
        }
        nm.createNotificationChannel(channel)
      }
    }

    Catapush.getInstance()
      .init(
        this,
        this,
        CatapushCordovaEventDelegate,
        Collections.singletonList(CatapushGms),
        CatapushCordovaIntentProvider(MainActivity::class.java),
        notificationTemplate,
        null,
        object : Callback<Boolean?> {
          override fun success(response: Boolean?) {
            LOG.d("CATAPUSH","Catapush has been successfully initialized")
          }
          override fun failure(irrecoverableError: Throwable) {
            LOG.e("CATAPUSH", "Can't initialize Catapush! " + irrecoverableError.localizedMessage)
          }
        })
  }

  private fun readCordovaConfig() {
    resources.apply {
      CHANNEL_ID = getString(getIdentifier("catapush_notification_channel_id", "string", packageName))
      CHANNEL_NAME = getString(getIdentifier("catapush_notification_channel_name", "string", packageName))
      NOTIFICATION_TITLE = getString(getIdentifier("catapush_notification_title", "string", packageName))
      val iconResName = getString(getIdentifier("catapush_notification_icon_res", "string", packageName))
      NOTIFICATION_ICON_RES_ID = getIdentifier(iconResName, "drawable", packageName)
      NOTIFICATION_COLOR = Color.parseColor(getString(getIdentifier("catapush_notification_color_hex", "string", packageName)))
    }
  }

}
