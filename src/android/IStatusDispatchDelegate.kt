package com.catapush.cordova.sdk

interface IStatusDispatchDelegate {
    fun dispatchConnectionStatus(status: String)
    fun dispatchError(event: String, code: Int)
}