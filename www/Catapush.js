var exec = require('cordova/exec');

var PLUGIN_NAME = "CatapushSdk";

class Catapush {
   static messageDelegate
   static stateDelegate

   constructor() { }

   static setCatapushMessageDelegate(delegate) {
      Catapush.messageDelegate = delegate
      if (delegate != null) {
         cordova.exec(
            (result) => {
               if (result.eventName === 'Catapush#catapushMessageReceived') {
                  Catapush.messageDelegate.catapushMessageReceived(result.message)
               } else if (result.eventName === 'Catapush#catapushMessageSent') {
                  Catapush.messageDelegate.catapushMessageSent(result.message)
               } else if (result.eventName === 'Catapush#catapushNotificationTapped') {
                  Catapush.messageDelegate.catapushNotificationTapped(result.message)
               }
            },
            (e) => console.error(e),
            PLUGIN_NAME,
            "subscribeMessageDelegate",
            []
         );
      } else {
         cordova.exec(
            null,
            (e) => console.error(e),
            PLUGIN_NAME,
            "unsubscribeMessageDelegate",
            []
         );
      }
   }

   static setCatapushStateDelegate(delegate) {
      Catapush.stateDelegate = delegate
      if (delegate != null) {
         cordova.exec(
            (result) => {
               if (result.eventName === 'Catapush#catapushStateChanged') {
                  Catapush.stateDelegate.catapushStateChanged(result.status.toUpperCase())
               } else if (result.eventName === 'Catapush#catapushHandleError') {
                  Catapush.stateDelegate.catapushHandleError({ event: result.event, code: result.code })
               }
            },
            (e) => console.error(e),
            PLUGIN_NAME,
            "subscribeStateDelegate",
            []
         );
      } else {
         cordova.exec(
            null,
            (e) => console.error(e),
            PLUGIN_NAME,
            "unsubscribeStateDelegate",
            []
         );
      }
   }

   static init(onSuccess, onError, appId) {
      exec(onSuccess, onError, PLUGIN_NAME, "init", [appId]);
   }

   static setUser(onSuccess, onError, identifier, password) {
      exec(onSuccess, onError, PLUGIN_NAME, "setUser", [identifier, password]);
   }

   static start(onSuccess, onError) {
      exec(onSuccess, onError, PLUGIN_NAME, "start", []);
   }

   static allMessages(onSuccess, onError) {
      exec(onSuccess, onError, PLUGIN_NAME, "allMessages", []);
   }

   static enableLog(onSuccess, onError, enabled) {
      exec(onSuccess, onError, PLUGIN_NAME, "enableLog", [enabled]);
   }

   static sendMessage(onSuccess, onError, message) {
      exec(onSuccess, onError, PLUGIN_NAME, "sendMessage", [message]);
   }

   static getAttachmentUrlForMessage(onSuccess, onError, message) {
      exec(onSuccess, onError, PLUGIN_NAME, "getAttachmentUrlForMessage", [message]);
   }

   static resumeNotifications(onSuccess, onError) {
      exec(onSuccess, onError, PLUGIN_NAME, "resumeNotifications");
   }

   static pauseNotifications(onSuccess, onError) {
      exec(onSuccess, onError, PLUGIN_NAME, "pauseNotifications");
   }

   static enableNotifications(onSuccess, onError) {
      exec(onSuccess, onError, PLUGIN_NAME, "enableNotifications");
   }

   static disableNotifications(onSuccess, onError) {
      exec(onSuccess, onError, PLUGIN_NAME, "disableNotifications");
   }

   static sendMessageReadNotificationWithId(onSuccess, onError, id) {
      exec(onSuccess, onError, PLUGIN_NAME, "sendMessageReadNotificationWithId", [id]);
   }
}

module.exports = Catapush;