// Type definitions for Catapush plugin
// Project: https://github.com/Catapush/catapush-cordova
// Definitions by: Catapush Team <https://www.catapush.com/>
// Definitions: https://github.com/DefinitelyTyped/DefinitelyTyped
// 
// Copyright (c) Catapush SRL
// Licensed under the Apache License, Version 2.0.

interface Navigator {
  /**
   * This plugin exposes Catapush SDK native features.
   */
  catapush: Catapush;
}

/**
 * This plugin exposes Catapush SDK native features.
 */
interface Catapush {

  /**
   * Sets a delegate that gets notified about new received or sent messages
   * @param delegate Object that implements the CatapushMessageDelegate interface callbacks
   */
  setCatapushMessageDelegate(delegate: CatapushMessageDelegate): void;

  /**
   * Sets a delegate that gets notified when the status of the SDK changes
   * @param delegate Object that implements the CatapushStateDelegate interface callbacks
   */
  setCatapushStateDelegate(delegate: CatapushStateDelegate): void;

  /**
   * Inits the Catapush native SDK.
   * @param onSuccess Success callback.
   * @param onError Error callback, that get an error message.
   * @param appId Your Catapush app ID, you can retrieve it from your dashboard.
   */
  init(
    onSuccess: () => void,
    onError: (message: string) => void,
    appId: string
  ): void;

  /**
   * Sets the user credentials in the Catapush native SDK.
   * @param onSuccess Success callback.
   * @param onError Error callback, that get an error message.
   * @param identifier Your Catapush user identifier.
   * @param password Your Catapush user password.
   */
  setUser(
    onSuccess: () => void,
    onError: (message: string) => void,
    identifier: string,
    password: string
  ): void;

  /**
   * Start the Catapush native service.
   * @param onSuccess Success callback.
   * @param onError Error callback, that get an error message.
   */
  start(
    onSuccess: () => void,
    onError: (message: string) => void
  ): void;

  /**
   * Retrieve all the Catapush messages stored for the current user.
   * @param onSuccess Success callback.
   * @param onError Error callback, that get an error message.
   */
  allMessages(
    onSuccess: (messages: CatapushMessage[]) => void,
    onError: (message: string) => void
  ): void;

  /**
   * Enable the Catapush native SDK logging.
   * @param onSuccess Success callback.
   * @param onError Error callback, that get an error message.
   * @param enabled Enable or disable logging passing true or false respectively.
   */
  enableLog(
    onSuccess: () => void,
    onError: (message: string) => void,
    enabled: boolean
  ): void;

  /**
   * Send a message to the Catapush server for delivery.
   * @param onSuccess Success callback.
   * @param onError Error callback, that get an error message.
   * @param message The message to be delivered.
   */
  sendMessage(
    onSuccess: () => void,
    onError: (message: string) => void,
    message: SendMessageParams
  ): void;

  /**
   * Get a message attachment URL.
   * @param onSuccess Success callback.
   * @param onError Error callback, that get an error message.
   * @param message The message which attachment needs to be retrieved.
   */
  getAttachmentUrlForMessage(
    onSuccess: (file: CatapushFile) => void,
    onError: (message: string) => void,
    message: CatapushMessage
  ): void;

  /**
   * Resume displaying notification to the user.
   * This setting is not persisted across Catapush SDK/app restarts.
   * Android only.
   * @param onSuccess Success callback.
   * @param onError Error callback, that get an error message.
   */
  resumeNotifications(
    onSuccess: () => void,
    onError: (message: string) => void
  ): void;

  /**
   * Pause displaying notification to the user.
   * This setting is not persisted across Catapush SDK/app restarts.
   * Android only.
   * @param onSuccess Success callback.
   * @param onError Error callback, that get an error message.
   */
  pauseNotifications(
    onSuccess: () => void,
    onError: (message: string) => void
  ): void;

  /**
   * Enable the notification of messages to the user in the status bar.
   * This setting is persisted across Catapush SDK/app restarts.
   * Android only.
   * @param onSuccess Success callback.
   * @param onError Error callback, that get an error message.
   */
  enableNotifications(
    onSuccess: () => void,
    onError: (message: string) => void
  ): void;

  /**
   * Disable the notification of messages to the user in the status bar.
   * This setting is persisted across Catapush SDK/app restarts.
   * Android only.
   * @param onSuccess Success callback.
   * @param onError Error callback, that get an error message.
   */
  disableNotifications(
    onSuccess: () => void,
    onError: (message: string) => void
  ): void;

  /**
   * Send the read notification of a message to the Catapush server.
   * @param onSuccess Success callback.
   * @param onError Error callback, that get an error message.
   * @param message The message to be marked as read.
   */
  sendMessageReadNotificationWithId(
    onSuccess: () => void,
    onError: (message: string) => void,
    id: string
  ): void;

}

interface CatapushMessage {
  id: string
  sender: string
  body?: string
  subject?: string
  previewText?: string
  hasAttachment: boolean
  channel?: string
  replyToId?: string
  optionalData?: Map<string, any>
  receivedTime?: Date
  readTime?: Date
  sentTime?: Date
  state: CatapushMessageState
}

interface SendMessageParams {
  body: string
  channel?: string
  replyTo?: string
  file?: CatapushFile
}

interface CatapushFile {
  mimeType: string
  url: string
}

interface CatapushError {
  event: string
  code: number
}

export const enum CatapushMessageState {
  RECEIVED = 'RECEIVED',
  RECEIVED_CONFIRMED = 'RECEIVED_CONFIRMED',
  OPENED = 'OPENED',
  OPENED_CONFIRMED = 'OPENED_CONFIRMED',
  NOT_SENT = 'NOT_SENT',
  SENT = 'SENT',
  SENT_CONFIRMED = 'SENT_CONFIRMED',
}

export const enum CatapushState {
  DISCONNECTED = 'DISCONNECTED',
  CONNECTING = 'CONNECTING',
  CONNECTED = 'CONNECTED',
}

interface CatapushMessageDelegate {
  catapushMessageReceived(message: CatapushMessage): void
  catapushMessageSent(message: CatapushMessage): void
}

interface CatapushStateDelegate {
  catapushStateChanged(state: CatapushState): void
  catapushHandleError(error: CatapushError): void
}
