package com.catapush.cordova.sdk

import com.catapush.library.messages.CatapushMessage

interface IMessagesDispatchDelegate {
    fun dispatchMessageReceived(message: CatapushMessage)
    fun dispatchMessageSent(message: CatapushMessage)
    fun dispatchNotificationTapped(message: CatapushMessage)
}