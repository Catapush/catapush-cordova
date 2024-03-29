# Setup Guide

In order to start sending push notifications and interacting with your mobile app users, follow the instructions below:

1. Create your account by [signing up](https://www.catapush.com/d/register) for Catapush services and register your app on our Private Panel
2. Generate a [iOS Push Certificate](https://www.catapush.com/docs-ios) and a [FCM Push Notification Key](https://github.com/Catapush/catapush-docs/blob/master/AndroidSDK/DOCUMENTATION_PLATFORM_GMS_FCM.md) or a [HMS Push Notification Key](https://github.com/Catapush/catapush-docs/blob/master/AndroidSDK/DOCUMENTATION_PLATFORM_HMS_PUSHKIT.md)
4. [Integrate React Native SDK](#Integrate_react_native_sdk)

## Integrate Cordova plugin

### Add Catapush Cordova plugin dependency
In the directory of your Ionic Cordova app project run this command replacing the variable values accordingly:
```bash
ionic cordova plugin add catapush-cordova-sdk \
  --variable CATAPUSH_APP_KEY="SET_YOUR_CATAPUSH_APP_KEY" \
  --variable NOTIFICATION_CHANNEL_ID="com.catapush.cordova.sdk.channel" \
  --variable NOTIFICATION_CHANNEL_NAME="Notification channel" \
  --variable NOTIFICATION_TITLE=" " \
  --variable NOTIFICATION_ICON_RES="ic_stat_notify" \
  --variable NOTIFICATION_COLOR_HEX="#50BFF7"
```

The variables will be stored in the `package.json` file of your app:
```json
{
  "name": "example",
  ...
  "cordova": {
    "plugins": {
      "catapush-cordova-sdk": {
        "CATAPUSH_APP_KEY": "SET_YOUR_CATAPUSH_APP_KEY",
        "NOTIFICATION_CHANNEL_ID": "com.catapush.cordova.sdk.channel",
        "NOTIFICATION_CHANNEL_NAME": "Notification channel",
        "NOTIFICATION_TITLE": " ",
        "NOTIFICATION_ICON_RES": "ic_stat_notify",
        "NOTIFICATION_COLOR_HEX": "#50BFF7"
      },
      ...
    },
    ...
  }
}
```

### [iOS] Add a Notification Service Extension
In order to process the push notification a Notification Service Extension is required.
Add a Notification Service Extension (in Xcode File -> New -> Target...) that extends ```CatapushNotificationServiceExtension```

```swift
import Foundation
import UserNotifications
import catapush_ios_sdk_pod

let PENDING_NOTIF_DAYS = 5 // Represents the maximum time of cached messages for catapushNotificationTapped callback
extension UNNotificationAttachment {
  static func create(identifier: String, image: UIImage, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
    let fileManager = FileManager.default
    let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
    let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
    do {
      try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
      let imageFileIdentifier = identifier+".png"
      let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
      let data = image.pngData()
      try data!.write(to: fileURL)
      let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL, options: options)
      return imageAttachment
    } catch {
    }
    return nil
  }
}

class NotificationService: CatapushNotificationServiceExtension {
  
  var receivedRequest: UNNotificationRequest?
  
  override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    self.receivedRequest = request;
    super.didReceive(request, withContentHandler: contentHandler)
  }
  
  override func handleMessage(_ message: MessageIP?, withContentHandler contentHandler: ((UNNotificationContent?) -> Void)?, withBestAttempt bestAttemptContent: UNMutableNotificationContent?) {
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      if (message != nil) {
        bestAttemptContent.body = message!.body;
        if message!.hasMediaPreview(), let image = message!.imageMediaPreview() {
          let identifier = ProcessInfo.processInfo.globallyUniqueString
          if let attachment = UNNotificationAttachment.create(identifier: identifier, image: image, options: nil) {
            bestAttemptContent.attachments = [attachment]
          }
        }
        let ud = UserDefaults.init(suiteName: (Bundle.main.object(forInfoDictionaryKey: "Catapush") as! (Dictionary<String,String>))["AppGroup"])
        let pendingMessages : Dictionary<String, String>? = ud!.object(forKey: "pendingMessages") as? Dictionary<String, String>
        var newPendingMessages: Dictionary<String, String>?
        if (pendingMessages == nil) {
            newPendingMessages = Dictionary()
        }else{
            let now = NSDate().timeIntervalSince1970
            newPendingMessages = pendingMessages!.filter({ pendingMessage in
                guard let timestamp = Double(pendingMessage.value.split(separator: "_").last ?? "") else {
                    return false
                }
                if (timestamp + Double(PENDING_NOTIF_DAYS*24*60*60)) > now {
                    return true
                }
                return false
            })
        }
        newPendingMessages![self.receivedRequest!.identifier] = "\(message!.messageId ?? "")_\(String(NSDate().timeIntervalSince1970))"
        ud!.setValue(newPendingMessages, forKey: "pendingMessages")
      }else{
        bestAttemptContent.body = NSLocalizedString("no_message", comment: "");
      }
      
      let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MessageIP")
      request.predicate = NSPredicate(format: "status = %i", MESSAGEIP_STATUS.MessageIP_NOT_READ.rawValue)
      request.includesSubentities = false
      do {
        let msgCount = try CatapushCoreData.managedObjectContext().count(for: request)
        bestAttemptContent.badge = NSNumber(value: msgCount)
      } catch _ {
      }
      
      contentHandler(bestAttemptContent);
    }
  }
  
  override func handleError(_ error: Error, withContentHandler contentHandler: ((UNNotificationContent?) -> Void)?, withBestAttempt bestAttemptContent: UNMutableNotificationContent?) {
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent{
      let errorCode = (error as NSError).code
      if (errorCode == CatapushCredentialsError) {
        bestAttemptContent.body = "Please login to receive messages"
      }
      if (errorCode == CatapushNetworkError) {
        bestAttemptContent.body = "Network problems"
      }
      if (errorCode == CatapushNoMessagesError) {
        if let request = self.receivedRequest, let catapushID = request.content.userInfo["catapushID"] as? String {
          let predicate = NSPredicate(format: "messageId = %@", catapushID)
          let matches = Catapush.messages(with: predicate)
          if matches.count > 0 {
            let message = matches.first! as! MessageIP
            if message.status.intValue == MESSAGEIP_STATUS.MessageIP_READ.rawValue{
              bestAttemptContent.body = "Message already read: " + message.body;
            }else{
              bestAttemptContent.body = "Message already received: " + message.body;
            }
            if message.hasMediaPreview(), let image = message.imageMediaPreview() {
              let identifier = ProcessInfo.processInfo.globallyUniqueString
              if let attachment = UNNotificationAttachment.create(identifier: identifier, image: image, options: nil) {
                bestAttemptContent.attachments = [attachment]
              }
            }
          }else{
            bestAttemptContent.body = "Open the application to verify the connection"
          }
        }else{
          bestAttemptContent.body = "Please open the app to read the message"
        }
      }
      if (errorCode == CatapushFileProtectionError) {
        bestAttemptContent.body = "Unlock the device at least once to receive the message"
      }
      if (errorCode == CatapushConflictErrorCode) {
        bestAttemptContent.body = "Connected from another resource"
      }
      if (errorCode == CatapushAppIsActive) {
        bestAttemptContent.body = "Please open the app to read the message"
      }
      contentHandler(bestAttemptContent);
    }
  }
}
```

### [iOS] App Groups
Catapush need that the Notification Service Extension and the main application can share resources.
In order to do that you have to create and enable a specific app group for both the application and the extension.
The app and the extension must be in the same app group.
<img src="https://github.com/Catapush/catapush-ios-sdk-pod/blob/master/images/appgroup_1.png">
<img src="https://github.com/Catapush/catapush-ios-sdk-pod/blob/master/images/appgroup_2.png">

You should also add this information in the App plist and the Extension plist (```group.example.group``` should match the one you used for example ```group.catapush.test``` in the screens):
```objectivec
    <key>Catapush</key>
    <dict>
        <key>AppGroup</key>
        <string>group.example.group</string>
    </dict>
```


### [Android] Enable Kotlin and AndroidX
In your app `config.xml` file add the necessary preferences to enable Kotlin and AndroidX and set target SDK 33 or higher for the Android builds:
```xml
<widget id="com.catapush.cordova.sdk.example" version="0.0.1" xmlns="http://www.w3.org/ns/widgets" xmlns:cdv="http://cordova.apache.org/ns/1.0">
  <name>example</name>
  ...
  <preference name="GradlePluginKotlinEnabled" value="true" />
  <preference name="GradlePluginKotlinCodeStyle" value="official" />
  <preference name="GradlePluginKotlinVersion" value="1.7.21" />
  <preference name="AndroidXEnabled" value="true" />
  ...
  <platform name="android">
    <preference name="android-targetSdkVersion" value="33" />
    ...
  </platform>
  ...
</widget>
```
If you're using cordova-android 12 or later you won't need to specify the target SDK version of 33.

### [Android] Import your google-services.json file 
Copy your `google-services.json` file in the root folder of your app project and declare it under the android platform node of your `config.xml`:
```xml
<widget id="com.catapush.cordova.sdk.example" version="0.0.1" xmlns="http://www.w3.org/ns/widgets" xmlns:cdv="http://cordova.apache.org/ns/1.0">
  <name>example</name>
  ...
  <platform name="android">
    <resource-file src="google-services.json" target="app/google-services.json" />
  ...
  </platform>
  ...
</widget>
```

### [Android] Application class customization

This plugin include a script that overrides your app class.
This class extends `MultidexApplication` and inits the native Catapush Android SDK for you, following the plugin preferences you set in your `package.json` file.

### [Android] MainActivity class customization

Your `MainActivity` implementation must forward the received `Intent`s to make the `catapushNotificationTapped` callback work:

```java
public class MainActivity extends CordovaActivity
{
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        CatapushCordovaIntentProvider.Companion.handleIntent(getIntent());
        ...
    }

  @Override
  protected void onNewIntent(Intent intent) {
    super.onNewIntent(intent);
    CatapushCordovaIntentProvider.Companion.handleIntent(intent);
  }

}
```

### [Android] Configure a push services provider

If you want to be able to receive the messages while your app is not running in the foreground you have to integrate one of the supported services providers: Google Mobile Services or Huawei Mobile Services.

- For GMS follow [this documentation section](https://github.com/Catapush/catapush-docs/blob/master/AndroidSDK/DOCUMENTATION_ANDROID_SDK.md#google-mobile-services-gms-module)

- For HMS follow [this documentation section](https://github.com/Catapush/catapush-docs/blob/master/AndroidSDK/DOCUMENTATION_ANDROID_SDK.md#huawei-mobile-services-hms-module)

### Initialize Catapush SDK
You can now initialize Catapush using the following code:

```js
Catapush.enableLog(true);

Catapush.init('YOUR_APP_KEY')
```

Register CatapushStateDelegate and CatapushMessageDelegate in order to recieve update regard the state of the connection and the state of the messages.

```js
    Catapush.setCatapushStateDelegate(stateDelegate)
    Catapush.setCatapushMessageDelegate(messageDelegate)
```

```js
export interface CatapushStateDelegate {
  catapushStateChanged(state: CatapushState): void
  catapushHandleError(error: CatapushError): void
}
```

```js
export interface CatapushMessageDelegate {
  catapushMessageReceived(message: CatapushMessage): void
  catapushMessageSent(message: CatapushMessage): void
}
```

### Basic usage
In order to start Catapush you have to set a user and call the start method.

```js
await Catapush.setUser('ios', 'ios')
Catapush.start()
```

To send a message:
```js
await Catapush.sendMessage(outboundMessage, null, null)
```

To receive a message check the catapushMessageReceived method of your CatapushMessageDelegate.
```js
catapushMessageReceived(message: CatapushMessage) {
    
}
```

To send read receipt:
```js
await Catapush.sendMessageReadNotificationWithId("id")
```

To retrieve all received messages:
```js
Catapush.allMessages(
  (messages: CatapushMessage[]) => {
    // success
  },
  (message: string) => {
    // error
  }
);
```


### Example project
The demo project is  in the `/example` folder of this repository.
