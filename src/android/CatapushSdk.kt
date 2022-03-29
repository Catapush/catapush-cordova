package com.catapush.cordova.sdk

import android.annotation.SuppressLint
import android.net.Uri
import android.util.Log
import com.catapush.library.Catapush
import com.catapush.library.interfaces.Callback
import com.catapush.library.interfaces.RecoverableErrorCallback
import com.catapush.library.messages.CatapushMessage
import org.apache.cordova.CallbackContext
import org.apache.cordova.CordovaPlugin
import org.apache.cordova.PluginResult
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream


class CatapushSdk : CordovaPlugin(), IMessagesDispatchDelegate, IStatusDispatchDelegate {

    private var messageCallbackContext: CallbackContext? = null
    private var stateCallbackContext: CallbackContext? = null

    init {
        CatapushCordovaReceiver.setMessagesDispatcher(this)
        CatapushCordovaReceiver.setStatusDispatcher(this)
    }

    override fun execute(
        action: String,
        args: JSONArray,
        callbackContext: CallbackContext
    ): Boolean {
        return when (action) {
            "subscribeMessageDelegate" -> {
              messageCallbackContext = callbackContext
              val pluginResult = PluginResult(PluginResult.Status.NO_RESULT)
              pluginResult.keepCallback = true
              callbackContext.sendPluginResult(pluginResult)
              true
            }
            "unsubscribeMessageDelegate" -> {
              messageCallbackContext = null
              val pluginResult = PluginResult(PluginResult.Status.NO_RESULT)
              callbackContext.sendPluginResult(pluginResult)
              true
            }
            "subscribeStateDelegate" -> {
              stateCallbackContext = callbackContext
              val pluginResult = PluginResult(PluginResult.Status.NO_RESULT)
              pluginResult.keepCallback = true
              callbackContext.sendPluginResult(pluginResult)
              true
            }
            "unsubscribeStateDelegate" -> {
              stateCallbackContext = null
              val pluginResult = PluginResult(PluginResult.Status.NO_RESULT)
              callbackContext.sendPluginResult(pluginResult)
              true
            }
            "init" -> {
                val appId = args.getString(0)
                init(appId, callbackContext)
                true
            }
            "setUser" -> {
                val identifier = args.getString(0)
                val password = args.getString(1)
                setUser(identifier, password, callbackContext)
                true
            }
            "start" -> {
                start(callbackContext)
                true
            }
            "allMessages" -> {
                allMessages(callbackContext)
                true
            }
            "enableLog" -> {
                val enabled = args.getBoolean(0)
                enableLog(enabled, callbackContext)
                true
            }
            "sendMessage" -> {
                val message = args.getJSONObject(0)
                sendMessage(message, callbackContext)
                true
            }
            "getAttachmentUrlForMessage" -> {
                val message = args.getJSONObject(0)
                getAttachmentUrlForMessage(message, callbackContext)
                true
            }
            "resumeNotifications" -> {
                resumeNotifications(callbackContext)
                true
            }
            "pauseNotifications" -> {
                pauseNotifications(callbackContext)
                true
            }
            "enableNotifications" -> {
                enableNotifications(callbackContext)
                true
            }
            "disableNotifications" -> {
                disableNotifications(callbackContext)
                true
            }
            "sendMessageReadNotificationWithId" -> {
                val id = args.getString(0)
                sendMessageReadNotificationWithId(id, callbackContext)
                true
            }
            else -> false
        }
    }

    override fun dispatchMessageReceived(message: CatapushMessage) {
        val params = JSONObject()
        params.put("message", message.toMap())
        sendMessageEvent("Catapush#catapushMessageReceived", params)
    }

    override fun dispatchMessageSent(message: CatapushMessage) {
        val params = JSONObject()
        params.put("message", message.toMap())
        sendMessageEvent("Catapush#catapushMessageSent", params)
    }

    override fun dispatchConnectionStatus(status: String) {
        val params = JSONObject()
        params.put("status", status)
        sendStateEvent("Catapush#catapushStateChanged", params)
    }

    override fun dispatchError(event: String, code: Int) {
        val params = JSONObject()
        params.put("event", event)
        params.put("code", code)
        sendStateEvent("Catapush#catapushHandleError", params)
    }

    @SuppressLint("RestrictedApi")
    private fun init(appId: String, callbackContext: CallbackContext) {
        if (Catapush.getInstance().isInitialized.blockingFirst(false)) {
            val pluginResult = PluginResult(PluginResult.Status.OK, true)
            pluginResult.keepCallback = true
            callbackContext.sendPluginResult(pluginResult)
        } else {
            callbackContext.error("Please invoke Catapush.getInstance().init(...) in the Application.onCreate(...) callback of your Android native app")
        }
    }

    private fun setUser(identifier: String, password: String, callbackContext: CallbackContext) {
        if (identifier.isNotBlank() && password.isNotBlank()) {
            Catapush.getInstance().setUser(identifier, password)
            callbackContext.success()
        } else {
            callbackContext.error("Arguments: identifier=$identifier password=$password")
        }
    }

    private fun start(callbackContext: CallbackContext) {
        Catapush.getInstance().start(object : RecoverableErrorCallback<Boolean> {
            override fun success(response: Boolean) {
                callbackContext.success()
            }
            override fun warning(recoverableError: Throwable) {
                Log.w("CatapushPluginModule", "Recoverable error", recoverableError)
            }
            override fun failure(irrecoverableError: Throwable) {
                callbackContext.error(irrecoverableError.localizedMessage)
            }
        })
    }

    private fun allMessages(callbackContext: CallbackContext) {
        Catapush.getInstance().getMessagesAsList(object : Callback<List<CatapushMessage>> {
            override fun success(response: List<CatapushMessage>) {
                callbackContext.success(response.toArray())
            }
            override fun failure(irrecoverableError: Throwable) {
                callbackContext.error(irrecoverableError.localizedMessage)
            }
        })
    }

    private fun enableLog(enabled: Boolean, callbackContext: CallbackContext) {
        if (enabled)
            Catapush.getInstance().enableLog()
        else
            Catapush.getInstance().disableLog()
        callbackContext.success()
    }

    private fun sendMessage(message: JSONObject, callbackContext: CallbackContext) {
        val body = if (message.has("body")) message.getString("body") else null
        val channel = if (message.has("channel")) message.getString("channel") else null
        val replyTo = if (message.has("replyTo")) message.getString("replyTo") else null
        val file = if (message.has("file")) message.getJSONObject("file") else null
        val fileUrl = if (file?.has("url") == true) file.getString("url") else null

        @SuppressLint("MissingPermission")
        if (!fileUrl.isNullOrBlank()) {
            val uri = fileUrl.let {
                if (it.startsWith("/")) {
                    Uri.parse("file://${it}")
                } else {
                    Uri.parse(it)
                }
            }
            //val mimeType = file["mimeType"] as String?
            Catapush.getInstance().sendFile(uri, body ?: "", channel, replyTo, object : Callback<Boolean> {
                override fun success(response: Boolean) {
                    callbackContext.success()
                }
                override fun failure(irrecoverableError: Throwable) {
                    callbackContext.error(irrecoverableError.localizedMessage)
                }
            })
        } else if (!body.isNullOrBlank()) {
            Catapush.getInstance().sendMessage(body, channel, replyTo, object : Callback<Boolean> {
                override fun success(response: Boolean) {
                    callbackContext.success()
                }
                override fun failure(irrecoverableError: Throwable) {
                    callbackContext.error(irrecoverableError.localizedMessage)
                }
            })
        } else {
            callbackContext.error("Please provide a body or an attachment (or both). Arguments: message=$message")
        }
    }

    private fun getAttachmentUrlForMessage(message: JSONObject, callbackContext: CallbackContext) {
        val id = if (message.has("id")) message.getString("id") else null
        if (id != null) {
            Catapush.getInstance().getMessageById(id, object : Callback<CatapushMessage> {
                override fun success(response: CatapushMessage) {
                    response.file().also { file ->
                        when {
                            file != null && response.isIn -> {
                                callbackContext.success(JSONObject().apply {
                                    put("url", file.remoteUri())
                                    put("mimeType", file.type())
                                })
                            }
                            file != null && !response.isIn -> {
                                callbackContext.success(JSONObject().apply {
                                    val localUri = if (file.localUri()?.startsWith("content://") == true) {
                                        val cacheDir = cordova.activity.applicationContext.cacheDir
                                        val fileName = "attachment_$id.tmp"
                                        val tempFile = File(cacheDir, fileName)
                                        if (!tempFile.exists()) {
                                            try {
                                                val newTempFile = File.createTempFile(fileName, null, cacheDir)
                                                val uri = Uri.parse(file.localUri()!!)
                                                val inStream = cordova.activity.contentResolver.openInputStream(uri)
                                                val outStream = FileOutputStream(newTempFile)
                                                val buffer = ByteArray(8 * 1024)
                                                var bytesRead: Int
                                                while (inStream!!.read(buffer)
                                                        .also { bytesRead = it } != -1
                                                ) {
                                                    outStream.write(buffer, 0, bytesRead)
                                                }
                                                inStream.close()
                                                outStream.close()
                                                newTempFile.absolutePath
                                            } catch (e: Exception) {
                                                // Fallback to remote file
                                                file.remoteUri()
                                            }
                                        } else {
                                            tempFile.absolutePath
                                        }
                                    } else {
                                        file.localUri()
                                    }
                                    put("url", localUri)
                                    put("mimeType", file.type())
                                })
                            }
                            else -> {
                                callbackContext.error("getAttachmentUrlForMessage unexpected CatapushMessage state or format")
                            }
                        }
                    }
                }
                override fun failure(irrecoverableError: Throwable) {
                    callbackContext.error(irrecoverableError.localizedMessage)
                }
            })
        } else {
            callbackContext.error("Id cannot be empty. Arguments: message=$message")
        }
    }

    private fun resumeNotifications(callbackContext: CallbackContext) {
        Catapush.getInstance().resumeNotifications()
        callbackContext.success()
    }

    private fun pauseNotifications(callbackContext: CallbackContext) {
        Catapush.getInstance().pauseNotifications()
        callbackContext.success()
    }

    private fun enableNotifications(callbackContext: CallbackContext) {
        Catapush.getInstance().enableNotifications()
        callbackContext.success()
    }

    private fun disableNotifications(callbackContext: CallbackContext) {
        Catapush.getInstance().disableNotifications()
        callbackContext.success()
    }

    private fun sendMessageReadNotificationWithId(id: String, callbackContext: CallbackContext) {
        Catapush.getInstance().notifyMessageOpened(id)
        callbackContext.success()
    }

    private fun sendMessageEvent(
        eventName: String,
        params: JSONObject
    ) {
        params.put("eventName", eventName)
        val pluginResult = PluginResult(PluginResult.Status.OK, params)
        pluginResult.keepCallback = true
        messageCallbackContext?.sendPluginResult(pluginResult)
    }

    private fun sendStateEvent(
      eventName: String,
      params: JSONObject
    ) {
      params.put("eventName", eventName)
      val pluginResult = PluginResult(PluginResult.Status.OK, params)
      pluginResult.keepCallback = true
      stateCallbackContext?.sendPluginResult(pluginResult)
    }

    private fun List<CatapushMessage>.toArray() : JSONArray {
        val array = JSONArray()
        forEach { array.put(it.toMap()) }
        return array
    }

    private fun CatapushMessage.toMap() : JSONObject {
        val obj = JSONObject()
        obj.put("id", this.id())
        obj.put("body", this.body())
        obj.put("subject", this.subject())
        obj.put("previewText", this.previewText())
        obj.put("sender", this.sender())
        obj.put("channel", this.channel())
        obj.put("optionalData", this.data()?.run {
            val data = JSONObject()
            forEach { (key, value) -> data.put(key, value) }
            return data
        })
        obj.put("replyToId", this.originalMessageId())
        obj.put("state", this.state())
        obj.put("receivedTime", this.receivedTime())
        obj.put("readTime", this.readTime())
        obj.put("sentTime", this.sentTime())
        obj.put("hasAttachment", this.file() != null)
        return obj
    }

}