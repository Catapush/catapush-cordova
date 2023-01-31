import catapush_ios_sdk_pod
import CoreServices

@objc(CatapushSdk) class CatapushSdk : CDVPlugin, MessageDispatchSendResult, StateDispatchSendResult {
    
    var catapushDelegate: CatapushDelegateClass?
    var messagesDispatcherDelegate: MessagesDispatchDelegateClass?
    var messageDelegateCommandCallback: CDVInvokedUrlCommand?
    var stateDelegateCommandCallback: CDVInvokedUrlCommand?

    @objc(`init`:)
    func `init`(command: CDVInvokedUrlCommand) {
        guard let appKey = command.argument(at: 0) as? String else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Bad argument"), callbackId: command.callbackId);
            return
        }
        Catapush.setAppKey(appKey)
        UNUserNotificationCenter.current().delegate = self
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
        catapushDelegate = CatapushDelegateClass(channel: self)
        messagesDispatcherDelegate = MessagesDispatchDelegateClass(channel: self)
        Catapush.setupCatapushStateDelegate(catapushDelegate, andMessagesDispatcherDelegate: messagesDispatcherDelegate)
    }
    
    func messageDispatchSendResult(result: CDVPluginResult) {
        guard let messageDelegateCommandCallback = messageDelegateCommandCallback else {
            return
        }
        self.commandDelegate.send(result, callbackId: messageDelegateCommandCallback.callbackId)
    }
    
    func stateDispatchSendResult(result: CDVPluginResult) {
        guard let stateDelegateCommandCallback = stateDelegateCommandCallback else {
            return
        }
        self.commandDelegate.send(result, callbackId: stateDelegateCommandCallback.callbackId)
    }
    
    @objc(subscribeMessageDelegate:)
    func subscribeMessageDelegate(command: CDVInvokedUrlCommand) {
        messageDelegateCommandCallback = command
        let result = CDVPluginResult(status: CDVCommandStatus_NO_RESULT)
        result?.keepCallback = true
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(subscribeStateDelegate:)
    func subscribeStateDelegate(command: CDVInvokedUrlCommand) {
        stateDelegateCommandCallback = command
        let result = CDVPluginResult(status: CDVCommandStatus_NO_RESULT)
        result?.keepCallback = true
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(unsubscribeMessageDelegate:)
    func unsubscribeMessageDelegate(command: CDVInvokedUrlCommand) {
        messageDelegateCommandCallback = nil
        let result = CDVPluginResult(status: CDVCommandStatus_NO_RESULT)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(unsubscribeStateDelegate:)
    func unsubscribeStateDelegate(command: CDVInvokedUrlCommand) {
        stateDelegateCommandCallback = nil
        let result = CDVPluginResult(status: CDVCommandStatus_NO_RESULT)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(pauseNotifications:)
    func pauseNotifications(command: CDVInvokedUrlCommand) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(enableLog:)
    func enableLog(command: CDVInvokedUrlCommand) {
        let enabled = command.argument(at: 0, withDefault: false) as? Bool ?? false
        Catapush.enableLog(enabled)
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(start:)
    func start(command: CDVInvokedUrlCommand) {
        var error: NSError?
        Catapush.start(&error)
        if let error = error {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.description), callbackId: command.callbackId);
        } else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId);
        }
    }
    
    @objc(setUser:)
    func setUser(command: CDVInvokedUrlCommand) {
        guard let identifier = command.argument(at: 0) as? String, let password = command.argument(at: 1) as? String else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Bad arguments"), callbackId: command.callbackId);
            return
        }
        Catapush.setIdentifier(identifier, andPassword: password)
        self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
    }
    
    @objc(allMessages:)
    func allMessages(command: CDVInvokedUrlCommand) {
        let result = (Catapush.allMessages() as! [MessageIP]).map {
            return CatapushSdk.formatMessageID(message: $0)
        }
        self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result), callbackId: command.callbackId)
    }

    @objc(sendMessage:)
    func sendMessage(command: CDVInvokedUrlCommand) {
        guard let arg = command.argument(at: 0) as? Dictionary<String,Any> else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Bad arguments"), callbackId: command.callbackId);
            return
        }
        let text = arg["text"] as? String
        let channel = arg["channel"] as? String
        let replyTo = arg["replyTo"] as? String
        let file = arg["file"] as? Dictionary<String, Any>
        let message: MessageIP?
        if let file = file, let url = file["url"] as? String, let mimeType = file["mimeType"] as? String, FileManager.default.fileExists(atPath: url){
            let data = FileManager.default.contents(atPath: url)
            if let channel = channel {
                if let replyTo = replyTo {
                    message = Catapush.sendMessage(withText: text, andChannel: channel, andData: data, ofType: mimeType, replyTo: replyTo)
                }else{
                    message = Catapush.sendMessage(withText: text, andChannel: channel, andData: data, ofType: mimeType)
                }
            }else{
                if let replyTo = replyTo {
                    message = Catapush.sendMessage(withText: text, andData: data, ofType: mimeType, replyTo: replyTo)
                }else{
                    message = Catapush.sendMessage(withText: text, andData: data, ofType: mimeType)
                }
            }
        }else{
            if let channel = channel {
                if let replyTo = replyTo {
                    message = Catapush.sendMessage(withText: text, andChannel: channel, replyTo: replyTo)
                }else{
                    message = Catapush.sendMessage(withText: text, andChannel: channel)
                }
            }else{
                if let replyTo = replyTo {
                    message = Catapush.sendMessage(withText: text, replyTo: replyTo)
                }else{
                    message = Catapush.sendMessage(withText: text)
                }
            }
        }
        guard let message = message else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR), callbackId: command.callbackId);
            return
        }
        self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: CatapushSdk.formatMessageID(message: message) as [AnyHashable : Any]), callbackId: command.callbackId)
    }
    
    @objc(getAttachmentUrlForMessage:)
    func getAttachmentUrlForMessage(command: CDVInvokedUrlCommand) {
        guard let id = command.argument(at: 0) as? String else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Bad argument"), callbackId: command.callbackId);
            return
        }
        
        let predicate = NSPredicate(format: "messageId = %@", id)
        let matches = Catapush.messages(with: predicate)
        if matches.count > 0 {
            let messageIP = matches.first! as! MessageIP
            if messageIP.hasMedia() {
                if messageIP.mm != nil {
                    guard let mime = messageIP.mmType,
                          let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime as CFString, nil),
                          let ext = UTTypeCopyPreferredTagWithClass(uti.takeRetainedValue(), kUTTagClassFilenameExtension) else{
                              return
                          }
                    let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
                    let filePath = tempDirectoryURL.appendingPathComponent("\(messageIP.messageId).\(ext.takeRetainedValue())")
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: filePath.path) {
                        self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["url": filePath.path, "mimeType": mime]), callbackId: command.callbackId)
                    }
                    do {
                        try messageIP.mm!.write(to: filePath)
                        self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["url": filePath.path, "mimeType": mime]), callbackId: command.callbackId)
                    } catch {
                        self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: ["error": error.localizedDescription]), callbackId: command.callbackId)
                    }
                }else{
                    messageIP.downloadMedia { (error, data) in
                        if(error != nil){
                            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: ["error": error?.localizedDescription ?? ""]), callbackId: command.callbackId)
                        }else{
                            let predicate = NSPredicate(format: "messageId = %@", id)
                            let matches = Catapush.messages(with: predicate)
                            if matches.count > 0 {
                                let messageIP = matches.first! as! MessageIP
                                if messageIP.hasMedia() {
                                    if messageIP.mm != nil {
                                        guard let mime = messageIP.mmType,
                                              let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime as CFString, nil),
                                              let ext = UTTypeCopyPreferredTagWithClass(uti.takeRetainedValue(), kUTTagClassFilenameExtension) else{
                                                  return
                                              }
                                        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
                                        let filePath = tempDirectoryURL.appendingPathComponent("\(messageIP.messageId).\(ext.takeRetainedValue())")
                                        let fileManager = FileManager.default
                                        if fileManager.fileExists(atPath: filePath.path) {
                                            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["url": filePath.path]), callbackId: command.callbackId)
                                        }
                                        do {
                                            try messageIP.mm!.write(to: filePath)
                                            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["url": filePath.path, "mimeType": mime]), callbackId: command.callbackId)
                                        } catch {
                                            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: ["error": error.localizedDescription]), callbackId: command.callbackId)
                                        }
                                    }else{
                                        self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["url": ""]), callbackId: command.callbackId)
                                    }
                                    return
                                }else{
                                    self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["url": ""]), callbackId: command.callbackId)
                                }
                            }else{
                                self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["url": ""]), callbackId: command.callbackId)
                            }
                        }
                    }
                }
                return
            }else{
                self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["url": ""]), callbackId: command.callbackId)
            }
        }else{
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["url": ""]), callbackId: command.callbackId)
        }
    }
    
    @objc(sendMessageReadNotificationWithId:)
    func sendMessageReadNotificationWithId(command: CDVInvokedUrlCommand) {
        guard let id = command.argument(at: 0) as? String else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Bad argument"), callbackId: command.callbackId);
            return
        }
        MessageIP.sendMessageReadNotification(withId: id)
        self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
    }
    
    public static func formatMessageID(message: MessageIP) -> Dictionary<String, Any?>{
        let formatter = ISO8601DateFormatter()
        
        return [
            "messageId": message.messageId,
            "body": message.body,
            "sender": message.sender,
            "channel": message.channel,
            "optionalData": message.optionalData(),
            "replyToId": message.originalMessageId,
            "state": getStateForMessage(message: message),
            "sentTime": formatter.string(from: message.sentTime),
            "hasAttachment": message.hasMedia()
        ];
    }
    
    public static func getStateForMessage(message: MessageIP) -> String{
        if message.type.intValue == MESSAGEIP_TYPE.MessageIP_TYPE_INCOMING.rawValue {
            if message.status.intValue == MESSAGEIP_STATUS.MessageIP_READ.rawValue{
                return "RECEIVED_CONFIRMED"
            }
            return "RECEIVED"
        }else{
            return "SENT"
        }
    }
    
    class CatapushDelegateClass : NSObject, CatapushDelegate {
        
        let channel: StateDispatchSendResult
        
        init(channel: StateDispatchSendResult) {
            self.channel = channel
        }
        
        let LONG_DELAY =  300
        let SHORT_DELAY = 30
        
        func catapushDidConnectSuccessfully(_ catapush: Catapush!) {
            
        }
        
        func catapush(_ catapush: Catapush!, didFailOperation operationName: String!, withError error: Error!) {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            if domain == CATAPUSH_ERROR_DOMAIN {
                switch code {
                case CatapushErrorCode.INVALID_APP_KEY.rawValue:
                    /*
                     Check the app id and retry.
                     [Catapush setAppKey:@"YOUR_APP_KEY"];
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "INVALID_APP_KEY",
                        "code": CatapushErrorCode.INVALID_APP_KEY.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.USER_NOT_FOUND.rawValue:
                    /*
                     Please check if you have provided a valid username and password to Catapush via this method:
                     [Catapush setIdentifier:username andPassword:password];
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "USER_NOT_FOUND",
                        "code": CatapushErrorCode.USER_NOT_FOUND.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.WRONG_AUTHENTICATION.rawValue:
                    /*
                     Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.
                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "WRONG_AUTHENTICATION",
                        "code": CatapushErrorCode.WRONG_AUTHENTICATION.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.GENERIC.rawValue:
                    /*
                     An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.XMPP_MULTIPLE_LOGIN.rawValue:
                    /*
                     The same user identifier has been logged on another device, the messaging service will be stopped on this device
                     Please check that you are using a unique identifier for each device, even on devices owned by the same user.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "XMPP_MULTIPLE_LOGIN",
                        "code": CatapushErrorCode.XMPP_MULTIPLE_LOGIN.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.API_UNAUTHORIZED.rawValue:
                    /*
                     The credentials has been rejected    Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.
                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "API_UNAUTHORIZED",
                        "code": CatapushErrorCode.API_UNAUTHORIZED.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.API_INTERNAL_ERROR.rawValue:
                    /*
                     Internal error of the remote messaging service
                     
                     An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.REGISTRATION_BAD_REQUEST.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.REGISTRATION_FORBIDDEN_WRONG_AUTH.rawValue:
                    /*
                     Wrong auth    Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.
                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "REGISTRATION_FORBIDDEN_WRONG_AUTH",
                        "code": CatapushErrorCode.REGISTRATION_FORBIDDEN_WRONG_AUTH.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.REGISTRATION_NOT_FOUND_APPLICATION.rawValue:
                    /*
                     Application not found
                     
                     You appplication is not found or not active.
                     You should not keep retrying.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "REGISTRATION_NOT_FOUND_APPLICATION",
                        "code": CatapushErrorCode.REGISTRATION_NOT_FOUND_APPLICATION.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.REGISTRATION_NOT_FOUND_USER.rawValue:
                    /*
                     User not found
                     The user has been probably deleted from the Catapush app (via API or from the dashboard).
                     You should not keep retrying.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "REGISTRATION_NOT_FOUND_USER",
                        "code": CatapushErrorCode.REGISTRATION_NOT_FOUND_USER.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.REGISTRATION_INTERNAL_ERROR.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.OAUTH_BAD_REQUEST.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.OAUTH_BAD_REQUEST_INVALID_CLIENT.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.OAUTH_BAD_REQUEST_INVALID_GRANT.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.OAUTH_INTERNAL_ERROR.rawValue:
                    /*
                     Internal error of the remote messaging service    An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     Please try again in a few minutes.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_FORBIDDEN_WRONG_AUTH.rawValue:
                    /*
                     Credentials error
                     
                     Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.
                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "UPDATE_PUSH_TOKEN_FORBIDDEN_WRONG_AUTH",
                        "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_FORBIDDEN_WRONG_AUTH.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_FORBIDDEN_NOT_PERMITTED.rawValue:
                    /*
                     Credentials error
                     
                     Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.
                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "UPDATE_PUSH_TOKEN_FORBIDDEN_NOT_PERMITTED",
                        "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_FORBIDDEN_NOT_PERMITTED.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_CUSTOMER.rawValue:
                    /*
                     Application error
                     
                     You appplication is not found or not active.
                     You should not keep retrying.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "UPDATE_PUSH_TOKEN_NOT_FOUND_CUSTOMER",
                        "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_CUSTOMER.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_APPLICATION.rawValue:
                    /*
                     Application not found
                     
                     You appplication is not found or not active.
                     You should not keep retrying.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "UPDATE_PUSH_TOKEN_NOT_FOUND_APPLICATION",
                        "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_APPLICATION.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_USER.rawValue:
                    /*
                     User not found
                     
                     Please verify your identifier and password validity. The user might have been deleted from the Catapush app (via API or from the dashboard) or the password has changed.
                     You should not keep retrying, delete the stored credentials.
                     Provide a new identifier to this installation to solve the issue.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "UPDATE_PUSH_TOKEN_NOT_FOUND_USER",
                        "code": CatapushErrorCode.UPDATE_PUSH_TOKEN_NOT_FOUND_USER.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                case CatapushErrorCode.UPDATE_PUSH_TOKEN_INTERNAL_ERROR.rawValue:
                    /*
                     Internal error of the remote messaging service when updating the push token.
                     
                     Nothing, it's handled automatically by the sdk.
                     An unexpected internal error on the remote messaging service has occurred.
                     This is probably due to a temporary service disruption.
                     */
                    self.retry(delayInSeconds: LONG_DELAY);
                    break;
                case CatapushErrorCode.NETWORK_ERROR.rawValue:
                    /*
                     The SDK couldn’t establish a connection to the Catapush remote messaging service.
                     
                     The device is not connected to the internet or it might be blocked by a firewall or the remote messaging service might be temporarily disrupted.    Please check your internet connection and try to reconnect again.
                     */
                    self.retry(delayInSeconds: SHORT_DELAY);
                    break;
                case CatapushErrorCode.PUSH_TOKEN_UNAVAILABLE.rawValue:
                    /*
                     Push token is not available.
                     
                     Nothing, it's handled automatically by the sdk.
                     */
                    let result = [
                        "eventName": "Catapush#catapushHandleError",
                        "event": "PUSH_TOKEN_UNAVAILABLE",
                        "code": CatapushErrorCode.PUSH_TOKEN_UNAVAILABLE.rawValue
                    ] as [String : Any]
                    channel.stateDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                    break;
                default:
                    break;
                }
            }
        }
        
        func retry(delayInSeconds:Int) {
            let deadlineTime = DispatchTime.now() + .seconds(delayInSeconds)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                var error: NSError?
                Catapush.start(&error)
                if error != nil {
                    // API KEY, USERNAME or PASSWORD not set
                }
            }
        }
    }
    
    class MessagesDispatchDelegateClass: NSObject, MessagesDispatchDelegate{
        let channel: MessageDispatchSendResult
        
        init(channel: MessageDispatchSendResult) {
            self.channel = channel
        }
        
        func libraryDidReceive(_ messageIP: MessageIP!) {
            let result = [
                "eventName": "Catapush#catapushMessageReceived",
                "message": CatapushSdk.formatMessageID(message: messageIP)
            ] as [String : Any]
            channel.messageDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
        }
    }
    

}

protocol MessageDispatchSendResult {
    func messageDispatchSendResult(result: CDVPluginResult)
}

protocol StateDispatchSendResult {
    func stateDispatchSendResult(result: CDVPluginResult)
}

extension CatapushSdk: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let ud = UserDefaults.init(suiteName: (Bundle.main.object(forInfoDictionaryKey: "Catapush") as! (Dictionary<String,String>))["AppGroup"])
        let pendingMessages : Dictionary<String, String>? = ud!.object(forKey: "pendingMessages") as? Dictionary<String, String>;
        if (pendingMessages != nil && pendingMessages![response.notification.request.identifier] != nil) {
            let id: String = String(pendingMessages![response.notification.request.identifier]!.split(separator: "_").first ?? "")
            let predicate = NSPredicate(format: "messageId == %@", id)
            let matches = Catapush.messages(with: predicate)
            if matches.count > 0, let messageIP = matches.first as? MessageIP {
                let result = [
                    "eventName": "Catapush#catapushNotificationTapped",
                    "message": CatapushSdk.formatMessageID(message: messageIP)
                ] as [String : Any]
                messageDispatchSendResult(result: CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result))
                var newPendingMessages: Dictionary<String, String>?
                if (pendingMessages == nil) {
                    newPendingMessages = Dictionary()
                }else{
                    newPendingMessages = pendingMessages!
                }
                newPendingMessages![response.notification.request.identifier] = nil;
                ud!.setValue(newPendingMessages, forKey: "pendingMessages")
            }
        }
        completionHandler();
    }
}
